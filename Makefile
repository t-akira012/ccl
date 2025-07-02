.PHONY: commit
commit: # sync to git
	git pull origin main
	git add --all
	if ! git diff --cached --quiet; then \
		git commit -m 'update'; \
		git push origin main ; \
	else \
		echo "no changes." ; \
	fi

deploy:
	export CURRENT_DIR=$${PWD}
	echo create-reverce-symlink
	mv $$CURRENT_DIR $$HOME/ccc/.ccl
	ln -si $$HOME/ccc/.ccl $$CURRENT_DIR
