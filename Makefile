.PHONY: runserver
runserver:
	@echo "Starting Django development server..."
	python src/manage.py runserver 0.0.0.0:8000
