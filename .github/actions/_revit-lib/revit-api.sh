# Общие функции для работы с API RevitWorker. Подключается через source.
# Ожидает переменные: API_URL, API_EMAIL, API_PASSWORD.
# После source доступны: API (адрес без завершающего /), TOKEN, login().

API="${API_URL%/}"
if [ -z "$API" ] || [ -z "$API_EMAIL" ] || [ -z "$API_PASSWORD" ]; then
  echo "::error::Секреты REVIT_API_URL / REVIT_API_EMAIL / REVIT_API_PASSWORD не заданы"
  exit 1
fi

TOKEN=""
login() {
  local body
  body=$(jq -n --arg email "$API_EMAIL" --arg password "$API_PASSWORD" \
    '{email: $email, password: $password}')
  local resp
  if ! resp=$(curl -sS --fail-with-body --retry 3 \
      -H 'Content-Type: application/json' \
      -d "$body" "$API/api/auth/login"); then
    echo "::error::Не удалось авторизоваться: $resp"
    exit 1
  fi
  TOKEN=$(jq -r '.token // empty' <<<"$resp")
  if [ -z "$TOKEN" ]; then
    echo "::error::Ответ логина не содержит token"
    exit 1
  fi
  echo "::add-mask::$TOKEN"
}
