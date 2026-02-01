# Example Feature V2 Migration - Summary

> **Example Archive:** This is an example of what archived task summaries should look like.

**Completed:** YYYY-MM
**Tags:** `schema`, `migration`, `backward-compat`, `json`
**Archived From:** `devdocs/example-feature-v2-migration/`

## What Was Built

- Migrated feature from V1 to V2 JSON schema
- Added backward compatibility layer for legacy data
- Updated all view models to use new data structures
- Created comprehensive unit tests for schema validation

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Used strategy pattern for schema versioning | Allows adding V3+ without changing existing code |
| Kept V1 parser for 30-day migration period | Smooth transition for existing users |
| Timestamps changed from strings to ISO8601 | Standard format, better sorting/comparison |

## Files Changed

- `models/Feature/FeatureData` - New V2 model
- `models/Feature/FeatureDataV1` - Legacy model (deprecated)
- `services/FeatureManager` - Added version detection
- `tests/Feature/FeatureDataModelCodingTests` - V1/V2 roundtrip tests

## Gotchas Discovered

1. **V1 timestamps were strings, V2 uses ISO8601**
   - Solution: Added custom decoder that handles both formats

2. **Null handling differs between versions**
   - V1 used empty strings, V2 uses optionals
   - Solution: Decoder normalizes empty strings to nil

3. **Unit tests need both V1 and V2 fixtures**
   - Added `FeatureData+Generator` with both versions

## Related Documentation

- Feature docs: `docs/features/ExampleFeature/`
- Schema files: `docs/features/ExampleFeature/schemas/`

## Lessons for Future Migrations

- Always support reading old format for at least 30 days
- Create Generator extensions for test data early
- Document schema differences in a comparison table
