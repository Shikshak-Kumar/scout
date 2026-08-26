import uuid
import jwt
from jwt import PyJWKClient
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.core.config import get_settings
from app.models import User

bearer = HTTPBearer(auto_error=False)

# Use Keycloak container hostname since FastAPI is in the same docker network
jwks_client = PyJWKClient("http://keycloak:8080/realms/scout/protocol/openid-connect/certs")

async def current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    try:
        # Fetch the public key from Keycloak to verify the JWT signature
        signing_key = jwks_client.get_signing_key_from_jwt(credentials.credentials)
        
        # We disable 'iss' and 'aud' checks temporarily to avoid Docker hostname mismatches
        # (Keycloak issues tokens with 'localhost:8080' but we fetch JWKS from 'keycloak:8080')
        payload = jwt.decode(
            credentials.credentials, 
            signing_key.key, 
            algorithms=["RS256"],
            options={"verify_aud": False, "verify_iss": False}
        )
        
        keycloak_id = payload.get("sub")
        email = payload.get("email")
        
        if not keycloak_id:
            raise HTTPException(status_code=401, detail="Invalid token: No subject")

        # Fallback email if Keycloak doesn't provide one
        if not email:
            email = f"{keycloak_id}@no-email.local"

        user = (
            await db.execute(select(User).where(User.keycloak_id == keycloak_id))
        ).scalar_one_or_none()

        if not user:
            # Just-In-Time Provisioning
            user = User(
                email=email.lower(),
                keycloak_id=keycloak_id,
                is_active=True,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            
        return user
    except jwt.PyJWTError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=401, detail="Authentication failed")
