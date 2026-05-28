.PHONY: ship

ship:
	@read -r -p "Commit message: " msg; \
	if [ -z "$$msg" ]; then echo "Aborted: empty commit message"; exit 1; fi; \
	branch=$$(git rev-parse --abbrev-ref HEAD); \
	git add -A && \
	git commit -m "$$msg" && \
	git push -u origin "$$branch" && \
	gh pr create --fill --head "$$branch"
