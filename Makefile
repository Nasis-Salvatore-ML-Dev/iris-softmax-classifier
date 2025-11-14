# =====================================================
# Makefile — Iris Softmax Classifier
# =====================================================

ENV_NAME = tf_env_clean
PYTHON_VERSION = 3.10
CONDA_ACTIVATE = source $$(conda info --base)/etc/profile.d/conda.sh && conda activate $(ENV_NAME)

.PHONY: help install clean format lint test train validate run-app deploy monitor

# ==================== DEFAULT TARGET ====================
help:
	@echo "🌿 Iris Classifier - MLOps Demo Workflow"
	@echo ""
	@echo "📋 SETUP & DEVELOPMENT:"
	@echo "  make install        - Setup Conda environment and dependencies"
	@echo "  make format         - Auto-format code (black + isort)"
	@echo "  make lint           - Check code quality (flake8)"
	@echo "  make test           - Run unit tests with pytest"
	@echo "  make test-coverage  - Run tests with coverage report"
	@echo ""
	@echo "🤖 MODEL DEVELOPMENT:"
	@echo "  make train          - Train model (with quality gates)"
	@echo "  make tune           - Hyperparameter tuning with GridSearchCV"
	@echo "  make validate       - Validate model artifact integrity"
	@echo "  make compare        - Compare original vs tuned models"
	@echo ""
	@echo "🚀 DEPLOYMENT:"
	@echo "  make run-app        - Run FastAPI locally (localhost:8080)"
	@echo "  make test-api       - Test local API endpoint"
	@echo "  make deploy         - Deploy to Google Cloud Run"
	@echo ""
	@echo "🔄 COMPLETE WORKFLOWS:"
	@echo "  make dev            - Full development cycle (format→test→train→run)"
	@echo "  make ci             - CI/CD pipeline simulation (test→train→validate)"
	@echo "  make prod           - Production deployment (ci→deploy)"
	@echo ""
	@echo "🧹 UTILITIES:"
	@echo "  make clean          - Remove artifacts and cache"
	@echo "  make monitor        - Open GCP monitoring dashboard"
	@echo ""

# ==================== SETUP ====================
install:
	@echo "🔍 Setting up environment '$(ENV_NAME)'..."
	@if ! conda env list | grep -q $(ENV_NAME); then \
		echo "Creating new Conda environment with Python $(PYTHON_VERSION)..."; \
		conda create -y -n $(ENV_NAME) python=$(PYTHON_VERSION); \
	else \
		echo "✅ Environment already exists"; \
	fi
	@echo "📦 Installing dependencies..."
	@$(CONDA_ACTIVATE) && pip install --upgrade pip && pip install -r requirements.txt
	@echo "✅ Setup complete! Run: conda activate $(ENV_NAME)"

# ==================== CODE QUALITY ====================
format:
	@echo "🧹 Formatting code..."
	@$(CONDA_ACTIVATE) && isort src/ app/ tests/
	@$(CONDA_ACTIVATE) && black src/ app/ tests/
	@echo "✅ Code formatted"

lint:
	@echo "🔍 Running linter..."
	@$(CONDA_ACTIVATE) && flake8 src/ app/ tests/ --max-line-length=88 --extend-ignore=E203,E501
	@echo "✅ Linting passed"

test:
	@echo "🧪 Running tests..."
	@$(CONDA_ACTIVATE) && pytest -v --tb=short
	@echo "✅ All tests passed"

test-coverage:
	@echo "📊 Running tests with coverage..."
	@$(CONDA_ACTIVATE) && pytest --cov=src --cov=app --cov-report=html --cov-report=term-missing
	@echo "✅ Coverage report generated at htmlcov/index.html"

# ==================== MODEL TRAINING ====================
train: lint test
	@echo "🚀 Training model (quality gates passed)..."
	@$(CONDA_ACTIVATE) && python -m src.train
	@echo "✅ Model saved to artifacts/model.pkl"

tune: lint test
	@echo "🎯 Running hyperparameter tuning..."
	@$(CONDA_ACTIVATE) && PYTHONPATH=. python src/tune.py
	@echo "✅ Tuned model saved to artifacts/tuned_model.pkl"

validate: train
	@echo "🔎 Validating model artifact..."
	@$(CONDA_ACTIVATE) && python -c "\
	import joblib; \
	import os; \
	assert os.path.exists('tuned_model.pkl'), '❌ Model artifact not found'; \
	model = joblib.load('tuned_model.pkl'); \
	assert 'pipeline' in model, '❌ Pipeline missing'; \
	assert 'metrics' in model, '❌ Metrics missing'; \
	assert 'target_names' in model, '❌ Target names missing'; \
	assert model['metrics']['accuracy'] >= 0.95, '❌ Accuracy below threshold'; \
	print('✅ Model validation passed'); \
	print(f\"   Accuracy: {model['metrics']['accuracy']:.4f}\"); \
	print(f\"   Targets: {model['target_names']}\");"
	@echo "✅ Model artifact is valid"

compare: train tune
	@echo "📊 Comparing models..."
	@$(CONDA_ACTIVATE) && python -c "\
	import joblib; \
	original = joblib.load('artifacts/model.pkl'); \
	tuned = joblib.load('artifacts/tuned_model.pkl'); \
	print('Original accuracy:', original['metrics']['accuracy']); \
	print('Tuned accuracy:   ', tuned['metrics']['accuracy']); \
	print('Best parameters: ', tuned['metrics']['best_params']);"

# ==================== LOCAL DEPLOYMENT ====================
run-app: lint test
	@echo "🚀 Starting FastAPI server at http://localhost:8080"
	@echo "📖 API docs available at http://localhost:8080/docs"
	@$(CONDA_ACTIVATE) && uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload &

test-api:
	@echo "🧪 Testing API endpoint..."
	@sleep 2
	@curl -X POST "http://localhost:8080/predict" \
		-H "Content-Type: application/json" \
		-d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' \
		&& echo "\n✅ API test passed" || echo "\n❌ API test failed"

# ===================== PUSHING TO GITHUB ===================

# initialize Git Repository
git-init:
	@echo "🔧 Initializing Git repository..."
	@git init
	@git branch -M main
	@echo "Enter GitHub repo URL (e.g. https://github.com/user/iris-softmax-classifier.git):"
	@read url; git remote add origin $$url
	@echo "✔ Git initialized and remote added."

# check status 
git-status:
	@echo "📄 Git status:"
	@git status

# add all changes
git-add:
	@echo "➕ Staging all changes..."
	@git add .
	@echo "✔ Changes staged."

# commit with auto message
git-commit:
	@echo "📝 Committing changes..."
	@if [ -z "$(m)" ]; then \
		git commit -m "Auto-commit: $(shell date '+%Y-%m-%d %H:%M:%S')"; \
	else \
		git commit -m "$(m)"; \
	fi
	@echo "✔ Commit complete."

# push to github
git-push:
	@echo "🚀 Pushing to GitHub..."
	@branch=$$(git rev-parse --abbrev-ref HEAD); \
	echo "Pushing branch $$branch..."; \
	git push -u origin $$branch
	@echo "✔ Push complete."

# full automation
sync: git-add git-commit git-push
	@echo "🔄 Git sync complete."

# version tag
tag:
	@echo "🏷 Creating version tag..."
	@if [ -z "$(v)" ]; then \
		echo "❌ ERROR: Provide version using v=1.0.0"; \
		exit 1; \
	fi
	@git tag -a $(v) -m "Version $(v)"
	@git push origin $(v)
	@echo "✔ Tag $(v) pushed."




# ==================== CLOUD DEPLOYMENT ====================
deploy: validate
	@echo "🚀 Deploying to Google Cloud Run..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh
	@echo "✅ Deployment complete"
	@echo "🔗 Service URL saved in deployment_url.txt"

monitor:
	@echo "📈 Opening monitoring dashboard..."
	@if [ -f deployment_url.txt ]; then \
		URL=$$(cat deployment_url.txt); \
		echo "Service URL: $$URL"; \
		echo "Logs: gcloud run services logs read iris-softmax-service-dev --region=us-central1"; \
	else \
		echo "⚠️  No deployment found. Run 'make deploy' first"; \
	fi

# ==================== COMPLETE WORKFLOWS ====================
dev: format lint test train validate run-app
	@echo "✅ Development workflow complete"

ci: lint test tune validate-tuned
	@echo "✅ CI pipeline complete - ready for deployment"

validate-tuned: tune
	@echo "🔎 Validating TUNED model artifact..."
	@$(CONDA_ACTIVATE) && python -c "\
	import joblib; \
	import os; \
	assert os.path.exists('artifacts/tuned_model.pkl'), '❌ Tuned model artifact not found'; \
	model = joblib.load('artifacts/tuned_model.pkl'); \
	assert 'pipeline' in model, '❌ Pipeline missing'; \
	assert 'metrics' in model, '❌ Metrics missing'; \
	assert 'target_names' in model, '❌ Target names missing'; \
	assert model['metrics']['accuracy'] >= 0.95, '❌ Accuracy below threshold'; \
	print('✅ Tuned model validation passed'); \
	print(f\"   Accuracy: {model['metrics']['accuracy']:.4f}\"); \
	print(f\"   Targets: {model['target_names']}\");"
	@echo "✅ Tuned model artifact is valid"

prod: ci deploy
	@echo "🎉 Production deployment complete"

# ==================== CLEANUP ====================
clean:
	@echo "🧹 Cleaning artifacts and cache..."
	@rm -rf artifacts/*.pkl
	@rm -rf .pytest_cache/
	@rm -rf htmlcov/
	@rm -rf .mypy_cache/
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete
	@echo "✅ Cleanup complete"

clean-all: clean
	@echo "🗑️  Removing Conda environment..."
	@conda env remove -n $(ENV_NAME) -y 2>/dev/null || echo "⚠️  Environment not found"
	@echo "✅ Full cleanup complete"
