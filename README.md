# MobiDL - modules

MobiDL - modules is a collection of tools wrapped in WDL to be used in any WDL workflow.

## How to use ?

### Submodule

You can use this module as a submodule in another repository.

```bash
cd MyWorkflow
git submodule add git@github.com:MobiDL/modules.git
git config --global diff.submodule log
git config status.submodulesummary 1
```

#### Update

```bash
git submodule update --remote modules
```
