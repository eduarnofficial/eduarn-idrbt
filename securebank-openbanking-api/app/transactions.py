from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .database import get_db
from .models import Account, Transaction, User
from .schemas import TransactionRequest, TransactionOut
from .auth import current_user

router = APIRouter(prefix="/api/v1/transactions", tags=["Transactions"])

@router.post("", response_model=TransactionOut)
def transfer(req: TransactionRequest, user: User = Depends(current_user), db: Session = Depends(get_db)):
    source = db.query(Account).filter(Account.user_id == user.id).first()
    target = db.get(Account, req.to_account)

    if not source:
        raise HTTPException(status_code=400, detail="Source account not found")
    if not target:
        raise HTTPException(status_code=404, detail="Target account not found")
    if target.id == source.id:
        raise HTTPException(status_code=400, detail="Cannot transfer to the same account")
    if source.balance < req.amount:
        raise HTTPException(status_code=400, detail="Insufficient funds")

    source.balance -= req.amount
    target.balance += req.amount
    tx = Transaction(
        account_id=source.id,
        transaction_type="DEBIT",
        amount=req.amount,
        description=req.description
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx
