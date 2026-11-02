# OpenCode brands its titles as "OC | <task>"; without this the badge lands in the tab name.
TITLE_BRANDS=("pi=π" "omp=π" "opencode=OC")

# Explicit per-kind zeros strip the prefixes already written, which AUTO_INDEX=0 alone does not.
AUTO_INDEX_WORKSPACES=0
AUTO_INDEX_TABS=0
AUTO_INDEX_AGENTS=0

# OpenCode truncates its own title at 40 characters; match it so the tab keeps the whole title.
MAX_TITLE_LEN=40
