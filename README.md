# Finance API

## Setup

**Requirements:** Ruby 4.0+, PostgreSQL

```bash
bin/setup          # install gems, create & migrate database
bin/rails server   # start on http://localhost:3000
```

To run the test suite:

```bash
bin/rails test
```

---

## API

### Create user

#### Will return user id and jwt token
```
curl -X POST http://localhost:3000/api/v1/users \
-H "Content-Type: application/json" \
-d '{"user": {"email": "alice@example.com"}}'
```
### Login (existing user)

Returns a new JWT token for an existing user (use when a token expired).
```
curl -X POST http://localhost:3000/api/v1/session \
	-H "Content-Type: application/json" \
	-d '{"session": {"email": "alice@example.com"}}'
```

Response example:
```
{ "token": "<JWT_TOKEN>" }
```
### Deposit/withdrawal
```
curl -X POST http://localhost:3000/api/v1/transactions \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <JWT_TOKEN>" \
-d '{"transaction": {"type": "deposit", "amount": "100.00"}}'
```
### Check balance
```
curl -X GET http://localhost:3000/api/v1/balance \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <JWT_TOKEN>"
```
### Transfer
```
curl -X POST http://localhost:3000/api/v1/transfers \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <JWT_TOKEN>" \
-d '{"transfer": {"receiver_email": "bob@example.com", "amount": "30.00"}}'
```
