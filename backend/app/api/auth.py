from datetime import datetime,timedelta,timezone
from fastapi import APIRouter,Depends,HTTPException
from sqlalchemy import select,update
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.models import User,RefreshToken
from app.schemas.api import RegisterIn,LoginIn,TokenPair,RefreshIn
from app.core.security import hash_password,verify_password,access_token,new_refresh_token,refresh_hash
from app.core.config import get_settings
router=APIRouter(prefix="/auth",tags=["auth"])
async def issue(db,user):
    raw,digest=new_refresh_token(); db.add(RefreshToken(user_id=user.id,token_hash=digest,expires_at=datetime.now(timezone.utc)+timedelta(days=get_settings().refresh_token_days))); await db.commit()
    return TokenPair(access_token=access_token(str(user.id)),refresh_token=raw)
@router.post("/register",response_model=TokenPair,status_code=201)
async def register(data:RegisterIn,db:AsyncSession=Depends(get_db)):
    if (await db.execute(select(User).where(User.email==data.email.lower()))).scalar_one_or_none(): raise HTTPException(409,"Email already registered")
    user=User(email=data.email.lower(),password_hash=hash_password(data.password)); db.add(user); await db.flush(); return await issue(db,user)
@router.post("/login",response_model=TokenPair)
async def login(data:LoginIn,db:AsyncSession=Depends(get_db)):
    user=(await db.execute(select(User).where(User.email==data.email.lower()))).scalar_one_or_none()
    if not user or not verify_password(data.password,user.password_hash): raise HTTPException(401,"Invalid credentials")
    return await issue(db,user)
@router.post("/refresh",response_model=TokenPair)
async def refresh(data:RefreshIn,db:AsyncSession=Depends(get_db)):
    row=(await db.execute(select(RefreshToken).where(RefreshToken.token_hash==refresh_hash(data.refresh_token),RefreshToken.revoked_at.is_(None),RefreshToken.expires_at>datetime.now(timezone.utc)))).scalar_one_or_none()
    if not row: raise HTTPException(401,"Invalid refresh token")
    row.revoked_at=datetime.now(timezone.utc); user=await db.get(User,row.user_id); return await issue(db,user)
