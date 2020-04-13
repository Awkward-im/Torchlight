NOW    : table have copies of data for different mods
TODO   : modids are in one string (like tags)
GOOD   : easier to add and filter by mod
BAD    : too many repeats (record counts)
REASON : economy of place, all mod list at once, can use id as index
EXAMPLE: SELECT title FROM pets WHERE id=<id> AND modids GLOB '*,<modid>,*'