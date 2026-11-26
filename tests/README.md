## Testing

### Requirements

- [Pytest-workflow](https://github.com/LUMC/pytest-workflow)
- Cromwell (to run workflows)

<br>

### Run tests

```bash
pytest \
	--keep-workflow-wd \
	--verbose \
	--git-aware \
	--basetemp=/path/to/anotherdir/ \
	tests/
```

WARNING: '/path/to/anotherdir' must exist on each node of cluster

Due to `--keep-workflow-wd` option, dirs `Name_of_my_test` present at `--basetemp` path (created by `pytest-workflow`) must be be deleted *manually* afterwards
