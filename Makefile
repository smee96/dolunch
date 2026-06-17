PROD_API   := https://dolunch-api.kyuhan-lee.workers.dev
DEV_API    := https://dolunch-api-dev.kyuhan-lee.workers.dev
DEVICE     := 972BECC6-B780-4B1D-BCA5-18E12B01A499

.PHONY: run run-prod run-dev api-dev api-prod api-deploy-dev api-deploy-prod

## ── Flutter ─────────────────────────────────────────────────────────────────
# 개발 모드 (기본)
run:
	cd app && flutter run -d $(DEVICE) \
		--dart-define=APP_ENV=dev \
		--dart-define=API_BASE_URL=$(PROD_API)

# 프로덕션 빌드 확인용
run-prod:
	cd app && flutter run -d $(DEVICE) \
		--dart-define=APP_ENV=prod \
		--dart-define=API_BASE_URL=$(PROD_API)

# 로컬 API 연결 (wrangler dev 실행 중)
run-local:
	cd app && flutter run -d $(DEVICE) \
		--dart-define=APP_ENV=dev \
		--dart-define=API_BASE_URL=http://localhost:8787

## ── Cloudflare Workers ───────────────────────────────────────────────────────
# 로컬 dev 서버
api-dev:
	cd api && npx wrangler dev --env dev

# Dev 환경 배포
api-deploy-dev:
	cd api && npx wrangler deploy --env dev

# Production 배포
api-deploy-prod:
	cd api && npx wrangler deploy

## ── iOS 빌드 ─────────────────────────────────────────────────────────────────
build-ios:
	cd app && flutter build ios --release \
		--dart-define=APP_ENV=prod \
		--dart-define=API_BASE_URL=$(PROD_API)
