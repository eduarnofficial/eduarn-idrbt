from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .database import get_db
from .models import Account, Transaction, User
from .schemas import AccountOut
from .auth import current_user

router = APIRouter(prefix="/api/v1/accounts", tags=["Accounts"])

@router.get("", response_model=list[AccountOut])
def list_accounts(user: User = Depends(current_user), db: Session = Depends(get_db)):
    return db.query(Account).filter(Account.user_id == user.id).all()

@router.get("/{account_id}", response_model=AccountOut)
def get_account(account_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)):
    # Critical BOLA/IDOR authorization check:
    account = db.query(Account).filter(
        Account.id == account_id,
        Account.user_id == user.id
    ).first()
    if not account:
        raise HTTPException(status_code=403, detail="You are not authorized to access this account")
    return account

@router.get("/{account_id}/transactions")
def get_transactions(account_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)):
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == user.id).first()
    if not account:
        raise HTTPException(status_code=403, detail="You are not authorized to access this account")
    return db.query(Transaction).filter(Transaction.account_id == account.id).all()
