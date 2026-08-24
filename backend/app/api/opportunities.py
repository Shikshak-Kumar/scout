import base64
from datetime import datetime,timezone
from uuid import UUID
from fastapi import APIRouter,Depends,HTTPException,Query
from sqlalchemy import select,or_,desc
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.api.deps import current_user
from app.models import Opportunity,User,SavedOpportunity
from app.schemas.api import OpportunityOut,FeedOut,SavedIn
router=APIRouter(prefix="/opportunities",tags=["opportunities"])
def encode_cursor(dt,id): return base64.urlsafe_b64encode(f"{dt.isoformat()}|{id}".encode()).decode()
def decode_cursor(value):
    try:
        raw=base64.urlsafe_b64decode(value).decode(); stamp,ident=raw.rsplit("|",1); return datetime.fromisoformat(stamp),UUID(ident)
    except Exception: raise HTTPException(400,"Invalid cursor")
@router.get("",response_model=FeedOut)
async def feed(cursor:str|None=None,limit:int=Query(20,ge=1,le=50),q:str|None=None,db:AsyncSession=Depends(get_db),user:User=Depends(current_user)):
    stmt=select(Opportunity).where(Opportunity.is_expired.is_(False))
    if q: stmt=stmt.where(or_(Opportunity.title.ilike(f"%{q}%"),Opportunity.organization.ilike(f"%{q}%"),Opportunity.description.ilike(f"%{q}%")))
    if cursor:
        dt,ident=decode_cursor(cursor); stmt=stmt.where(or_(Opportunity.first_seen_at<dt,(Opportunity.first_seen_at==dt)&(Opportunity.id<ident)))
    rows=(await db.execute(stmt.order_by(desc(Opportunity.first_seen_at),desc(Opportunity.id)).limit(limit+1))).scalars().all(); more=len(rows)>limit; rows=rows[:limit]
    return FeedOut(items=rows,next_cursor=encode_cursor(rows[-1].first_seen_at,rows[-1].id) if more else None,last_updated=max((x.last_seen_at for x in rows),default=None))
@router.get("/{opportunity_id}",response_model=OpportunityOut)
async def detail(opportunity_id:UUID,db:AsyncSession=Depends(get_db),user:User=Depends(current_user)):
    value=await db.get(Opportunity,opportunity_id)
    if not value: raise HTTPException(404,"Opportunity not found")
    return value
@router.put("/{opportunity_id}/saved",status_code=204)
async def save(opportunity_id:UUID,data:SavedIn,db:AsyncSession=Depends(get_db),user:User=Depends(current_user)):
    if not await db.get(Opportunity,opportunity_id): raise HTTPException(404,"Opportunity not found")
    row=(await db.execute(select(SavedOpportunity).where(SavedOpportunity.user_id==user.id,SavedOpportunity.opportunity_id==opportunity_id))).scalar_one_or_none()
    if row: row.status=data.status; row.notes=data.notes
    else: db.add(SavedOpportunity(user_id=user.id,opportunity_id=opportunity_id,status=data.status,notes=data.notes))
    await db.commit()

