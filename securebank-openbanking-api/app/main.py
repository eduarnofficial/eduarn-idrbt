from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import init_db
from .auth import router as auth_router
from .accounts import router as accounts_router
from .transactions import router as transactions_router

app = FastAPI(title="SecureBank Open Banking API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Demo only. Restrict in production.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(accounts_router)
app.include_router(transactions_router)

@app.on_event("startup")
def startup():
    init_db()

@app.get("/")
def root():
    return {"service": "SecureBank Open Banking API", "status": "running"}

@app.get("/health")
def health():
    return {"status": "healthy"}
