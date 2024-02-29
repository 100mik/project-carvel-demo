### ytt

### Speaker notes
- Intro
    - Start off with base config, deduplicate labels with a function (To run `ytt -f config`)
    - Add templating, ytt fails without defaults
    - Demonstrate defaulting with values schema, ytt respects defaults
    - Introduce conditional namespacing (while rendering ytt)
    - Render template live while toying with values file (`ytt -f config --data-values-file values.yaml`) 
- Overlays
    - Start with an overlay that annotates all resources with `foo: bar`
    - Scope overlay to config map only
    - Show how an empty overlay can remove a resource
    - Change overlay to `kapp.k14s.io/versioned: ""` , mention that we will see what this does next