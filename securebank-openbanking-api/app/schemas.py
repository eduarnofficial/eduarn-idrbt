from pydantic import BaseModel, Field

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class AccountOut(BaseModel):
    id: int
    account_number: str
    account_type: str
    balance: float

class TransactionRequest(BaseModel):
    to_account: int = Field(gt=0)
    amount: float = Field(gt=0, le=100000)
    description: str = Field(min_length=1, max_length=200)

class TransactionOut(BaseModel):
    id: int
    account_id: int
    transaction_type: str
    amount: float
    description: str
