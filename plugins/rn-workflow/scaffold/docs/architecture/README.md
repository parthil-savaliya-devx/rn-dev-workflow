# Architecture

<!-- FILL IN: one paragraph describing this app — runtime (RN version, React version),
the backend boundary, how navigation/data/state are structured. -->

This is a React Native CLI app. Navigation is a native stack; remote data lives in React Query; local/persisted state in Zustand + MMKV. Each topical file below covers one area. Decisions and trade-offs live in [`../decisions/`](../decisions/README.md).

## Component tree

<!-- FILL IN: your provider/wrapper tree. Example: -->

```
<QueryClientProvider client={queryClient}>
  <AppWrapper>
    <NavigationContainer>
      <RootNavigator />
    </NavigationContainer>
  </AppWrapper>
</QueryClientProvider>
```

## Module map

| Module     | Path              | What it does |
| ---------- | ----------------- | ------------ |
| Screens    | `src/screens/`    | <FILL IN> |
| Components | `src/components/` | <FILL IN> |
| Navigation | `src/navigation/` | <FILL IN> |
| Hooks      | `src/hooks/`      | query + behaviour hooks (every hook has a test) |
| Services   | `src/services/`   | boundary fetcher, query client, errors |
| Store      | `src/store/`      | Zustand stores + MMKV adapter |
| Utils      | `src/utils/`      | pure functions (every util has a test) |
| Theme      | `src/theme/`      | design tokens |

## Where to go next

Add one numbered file per subsystem as it lands (`01-tech-stack.md`, `02-state-and-storage.md`, `03-data-layer.md`, …) and link it here. The AI-workflow doc is seeded:

- [18 — AI-Assisted Development Workflow](18-ai-dev-workflow.md): the tech-DNA genome, the `/feature` and `/fix` commands, the enforcement hooks, and how work is done consistently in this repo.
