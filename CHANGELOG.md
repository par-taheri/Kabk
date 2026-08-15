# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-15

### Added
- Initial stable release of the `kabk` gem.
- Framework-agnostic core engine for Schema-Driven Dynamic Admin Specification (Protocol v1.6.0).
- Resource registration DSL with declarative field definitions, relationships, and lifecycle hooks (`before_create`, `after_create`, `before_update`, `after_update`, `before_delete`, `after_delete`).
- Generic CRUD REST Engine (`Kabk::RestEngine`) with support for pagination, sorting, filtering (exact match, IN lists, range queries), and search.
- Pluggable ORM Adapter architecture with built-in `Kabk::Adapters::SequelAdapter`.
- Robust server-side validation and parameter sanitization (`Kabk::Validator`).
- Optimistic Concurrency Control (OCC) conflict detection (`Kabk::Concurrency`).
- Relational data hydration (`Kabk::RelationHydrator`) to eliminate N+1 queries.
- JSON Schema manifest generation (`Kabk::SchemaRenderer`) for dynamic UI configuration.
- Comprehensive YARD documentation and RSpec test suite.
