### ytt

### Speaker notes
- Intro
    - Start off with base config, deduplicate labels with a function (To run `ytt -f config`)
    - Add templating, ytt fails without defaults
        - 💡 have to move out of `enter`
        - 💡 maybe do a for-loop first with ports (?)
    - add a data-value for the label "channel", and maybe the ports
        - showcase from the cli through --data-values
        - add a schema
    - Demonstrate defaulting with values schema, ytt respects defaults
        - 💡 don't showcase defaults
    - Introduce conditional namespacing (while rendering ytt)
        - 🤔 then you kinda-sorta need to use template.replace
    - use another data-values file with --data-values-file
    - Render template live while toying with values file (`ytt -f config --data-values-file values.yaml`) 
- Overlays
    - Start with an overlay that annotates all resources with `foo: bar`
        - 💡 Use `apiVersion: v1soumik1` instead
    - Scope overlay to config map only
    - Show how an empty overlay can remove a resource
    (????)
    - Change overlay to `kapp.k14s.io/versioned: ""` , mention that we will see what this does next
