## create user

### Will return user id and jwt token

curl -X POST http://localhost:3000/api/v1/users \
-H "Content-Type: application/json" \
-d '{"user": {"email": "alice@example.com"}}'

## deposit/withdrawal

curl -X POST http://localhost:3000/api/v1/users/<USER_ID>/transactions \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <JWT_TOKEN>" \
-d '{"transaction": {"type": "deposit", "amount_cents": 10000}}'

## check balance

curl -X GET http://localhost:3000/api/v1/users/<USER_ID>/balance \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <JWT_TOKEN>"

## transfer

curl -X POST http://localhost:3000/api/v1/transfers \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <JWT_TOKEN>" \
-d '{"transfer": {"sender_id": <SENDER_ID>>, <RECEIVER_ID>: 2, "amount_cents": 3000}}'
