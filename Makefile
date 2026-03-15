PORT ?= 8888
ARGS ?=
UV_RUN = uv run
PYTHON = $(UV_RUN) python

.PHONY: help setup lint test check parse descriptions score site-data prompt build pipeline serve

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "; printf "Available targets:\n"} /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install project dependencies
	uv sync --extra dev

lint: ## Run Ruff checks
	uvx ruff check .

test: ## Run the test suite
	$(UV_RUN) pytest

check: lint test ## Run lint and tests

parse: ## Parse MOM wage workbook into sg_occupations.json/csv
	$(PYTHON) -m scripts.parse_wages $(ARGS)

descriptions: ## Build pages/ from SSOC definitions
	$(PYTHON) -m scripts.build_descriptions $(ARGS)

score: ## Score occupations with Claude CLI (pass ARGS='--start 0 --end 20')
	$(PYTHON) -m scripts.score $(ARGS)

site-data: ## Build site/data.json from occupations and scores
	$(PYTHON) -m scripts.build_site_data $(ARGS)

prompt: ## Generate prompt.md from site/data.json
	$(PYTHON) -m scripts.make_prompt $(ARGS)

build: site-data prompt ## Refresh site data and prompt

pipeline: parse descriptions site-data prompt ## Rebuild local artifacts except scoring

serve: ## Serve site/ locally (PORT=8888 by default)
	cd site && $(PYTHON) -m http.server $(PORT)
