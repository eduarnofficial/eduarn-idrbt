import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./data/securebank.db")

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

class Base(DeclarativeBase):
    pass

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    from . import models
    os.makedirs("data", exist_ok=True)
    Base.metadata.create_all(bind=engine)
    seed_demo_data()

def seed_demo_data():
    from .models import User, Account, Transaction
    from .security import hash_password
    db = SessionLocal()
    try:
        if db.query(User).count() > 0:
            return
        alice = User(username="alice", password_hash=hash_password("password123"), role="customer")
        bob = User(username="bob", password_hash=hash_password("password123"), role="customer")
        db.add_all([alice, bob])
        db.flush()

        a1 = Account(user_id=alice.id, account_number="SB1001", account_type="SAVINGS", balance=12500.50)
        a2 = Account(user_id=bob.id, account_number="SB1002", account_type="CURRENT", balance=28750.75)
        db.add_all([a1, a2])
        db.flush()

        db.add_all([
            Transaction(account_id=a1.id, transaction_type="CREDIT", amount=5000, description="Salary"),
            Transaction(account_id=a1.id, transaction_type="DEBIT", amount=250, description="Utility payment"),
            Transaction(account_id=a2.id, transaction_type="CREDIT", amount=10000, description="Business income"),
        ])
        db.commit()
    finally:
        db.close()
