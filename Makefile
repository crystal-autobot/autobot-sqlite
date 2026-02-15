.PHONY: test clean

test:
	@echo "Running tests..."
	crystal spec

clean:
	@echo "Cleaning..."
	rm -rf lib .shards
