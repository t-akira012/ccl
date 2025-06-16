# Git管理
commit: # sync to git
	git pull origin main
	git add --all
	if ! git diff --cached --quiet; then \
		git commit -m 'update'; \
		git push origin main ; \
	else \
		echo "no changes." ; \
	fi

# Docker Compose コマンド
up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f

shell:
	docker compose exec claude-code-log bash

# 管理コマンド
clean:
	docker compose down --volumes --remove-orphans

restart:
	docker compose restart

# 会話ログ関連
save:
	./save-chat.sh "$(TITLE)"

list:
	./list-chats.sh $(DATE)

search:
	./search-chats.sh "$(KEYWORD)"

showlog:
	./showlog.sh
