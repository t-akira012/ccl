.PHONY: commit up down exec logs
commit: # sync to git
	git pull origin main
	git add --all
	if ! git diff --cached --quiet; then \
		git commit -m 'update'; \
		git push origin main ; \
	else \
		echo "no changes." ; \
	fi

up: # start container
	docker compose up -d

down: # stop container
	docker compose down

exec: # exec into container
	docker compose exec claude-code-log bash

logs: # show container logs
	docker compose logs -f
