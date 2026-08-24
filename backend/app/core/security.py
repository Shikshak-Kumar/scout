import hashlib, secrets
from datetime import datetime, timedelta, timezone
import jwt
from pwdlib import PasswordHash
from app.core.config import get_settings
passwords=PasswordHash.recommended()
def hash_password(value:str)->str: return passwords.hash(value)
def verify_password(value:str, hashed:str)->bool: return passwords.verify(value, hashed)
def access_token(user_id:str)->str:
    s=get_settings(); now=datetime.now(timezone.utc)
    return jwt.encode({"sub":user_id,"type":"access","iat":now,"exp":now+timedelta(minutes=s.access_token_minutes)},s.jwt_secret,algorithm="HS256")
def new_refresh_token()->tuple[str,str]:
    raw=secrets.token_urlsafe(48); return raw, hashlib.sha256(raw.encode()).hexdigest()
def refresh_hash(raw:str)->str: return hashlib.sha256(raw.encode()).hexdigest()

