### ytt

### Speaker notes

- Templating
    - Start off with base config
    - `node_port` variables
    - Deduplicate labels with a function (To run `ytt -f starters/`)
    - Introduce a for-loop for the ports
    - Add a data-value for the label "channel"
        - Show that it fails
        - Pass it through the cli with --data-value
    - Showcase a data-values file, with "channel", "node_ports" and "namespace"
    - Showcase another --data-values-file
    - Activate values-schema, and showcase that changing the port type to ["30000"] fails
    - Introduce conditional namespacing (while rendering ytt)

- Overlays
    - Start with an overlay that changes `apiVersion: v1soumik1`
    - Scope overlay to deployment only
    - Show how an empty overlay can remove a resource (remove service)
