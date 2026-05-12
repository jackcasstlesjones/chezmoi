You are rewriting a design specification document. The current version was built up through iterative conversation — fixing one issue at a time, noting what was wrong, and patching corrections in place. This has left structural baggage: sections comparing what the spec previously said vs what it says now, conversation artifacts ("my earlier suggestion was wrong", "confirmed after discussion"), and inline corrections referencing prior drafts of the document itself.

The doc is still carrying baggage from these iterative fixes rather than being designed clean. It should be a spec, not a changelog of a spec.

Rewrite the document as a clean specification describing only the target state. The reader is an implementer who has never read the previous versions of the spec. They need to know what to build, not the series of decisions that got us to this point.

Rules:

- State what each value **is**, not what a previous draft got wrong
- No references to earlier versions of this document or the conversation that produced it
- No conversation artifacts ("I was wrong about", "confirmed after discussion", "both the code and my doc use X which resolves correctly")
- Design rationale belongs in a dedicated section, not scattered as inline corrections
- Instructions about what to change in the codebase are fine — instructions about what changed in the spec are not
