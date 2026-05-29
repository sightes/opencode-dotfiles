# TypeScript Guide Knowledge Base

Comprehensive TypeScript best practices, patterns, and type-level programming.

## How to Use This File

1. **Type design**: How to model domains with types
2. **Advanced patterns**: Generics, mapped types, conditional types
3. **Configuration**: tsconfig setup for different environments
4. **Migration strategies**: JavaScript to TypeScript
5. **Performance**: Type-level optimizations and build speed

---

## Core Principles

### Type Safety Levels

1. **Strictest Configuration**: Enable all strict flags
   ```json
   {
     "compilerOptions": {
       "strict": true,
       "noImplicitAny": true,
       "strictNullChecks": true,
       "strictFunctionTypes": true,
       "noUncheckedIndexedAccess": true
     }
   }
   ```

2. **Avoid `any`**: Use `unknown` for truly unknown values
   ```typescript
   // ❌ Bad
   function process(data: any) { return data.id }
   
   // ✅ Good
   function process(data: unknown) {
     if (typeof data === 'object' && data !== null && 'id' in data) {
       return (data as { id: string }).id
     }
     throw new Error('Invalid data')
   }
   ```

3. **Explicit Return Types**: Public APIs should have explicit return types
   ```typescript
   // ✅ Good - self-documenting, catches implementation errors
   export function calculateTotal(items: Item[]): number {
     return items.reduce((sum, item) => sum + item.price, 0)
   }
   ```

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Interface | PascalCase | `UserProfile` |
| Type alias | PascalCase | `UserID` |
| Enum | PascalCase | `OrderStatus` |
| Generic | T, K, V or descriptive | `T`, `TData`, `TKey` |
| Boolean variables | is/has/should prefix | `isLoading`, `hasPermission` |
| Constants | UPPER_SNAKE | `MAX_RETRY_COUNT` |
| Functions | camelCase | `fetchUserData` |

---

## Type System Deep Dive

### Discriminated Unions (Tagged Unions)

Best pattern for state machines and reducers:

```typescript
type LoadingState = { status: 'loading' }
type SuccessState<T> = { status: 'success'; data: T }
type ErrorState = { status: 'error'; error: string }
type AsyncState<T> = LoadingState | SuccessState<T> | ErrorState

// Usage - exhaustive type checking
function handleState<T>(state: AsyncState<T>) {
  switch (state.status) {
    case 'loading':
      return 'Loading...'
    case 'success':
      return state.data  // T is accessible here
    case 'error':
      return state.error
    default:
      // TypeScript ensures exhaustiveness
      const _exhaustive: never = state
      return _exhaustive
  }
}
```

### Generics Patterns

**1. Generic with Constraints:**
```typescript
function getKey<T extends Record<string, unknown>>(obj: T, key: keyof T) {
  return obj[key]
}
```

**2. Generic with Defaults:**
```typescript
interface ApiResponse<TData = unknown, TError = string> {
  success: boolean
  data?: TData
  error?: TError
}

// Usage
const userResponse: ApiResponse<User>  // TError defaults to string
```

**3. Type-safe Currying:**
```typescript
function createAction<TType extends string, TPayload>(type: TType) {
  return (payload: TPayload) => ({ type, payload })
}

const setUser = createAction<'SET_USER', User>('SET_USER')
// Result: (payload: User) => { type: 'SET_USER', payload: User }
```

### Mapped Types

**1. Make All Properties Optional:**
```typescript
type Partial<T> = { [K in keyof T]?: T[K] }
```

**2. Make All Properties Required:**
```typescript
type Required<T> = { [K in keyof T]-?: T[K] }
```

**3. Pick Specific Properties:**
```typescript
type Pick<T, K extends keyof T> = { [P in K]: T[P] }
type UserPreview = Pick<User, 'id' | 'name' | 'avatar'>
```

**4. Create Immutable Version:**
```typescript
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object
    ? DeepReadonly<T[K]>
    : T[K]
}
```

**5. Flatten Nested Object (FlattenPaths):**
```typescript
type FlattenPaths<T, Prefix extends string = ''> = {
  [K in keyof T]: T[K] extends object
    ? FlattenPaths<T[K], `${Prefix}${K & string}.`>
    : `${Prefix}${K & string}`
}[keyof T]
```

### Conditional Types

**1. Extract Return Type:**
```typescript
type ReturnType<T extends (...args: any[]) => any> = 
  T extends (...args: any[]) => infer R ? R : never
```

**2. Extract Promise Type:**
```typescript
type Awaited<T> = T extends Promise<infer R> ? R : T
```

**3. Nullable Utility:**
```typescript
type Nullable<T> = T | null
type NonNullable<T> = T extends null | undefined ? never : T
```

**4. Brand Types (Nominal Typing):**
```typescript
type Brand<T, B> = T & { __brand: B }
type UserID = Brand<string, 'UserID'>
type OrderID = Brand<string, 'OrderID'>

// Now you can't accidentally mix UserID and OrderID
function getUser(id: UserID) { /* ... */ }
getUser('123' as OrderID) // ❌ Error!
```

---

## Practical Patterns

### API Layer Type Safety

```typescript
// api/types.ts
interface ApiResponse<T> {
  data: T
  meta?: { page: number; total: number }
}

interface ApiError {
  code: string
  message: string
  details?: Record<string, string[]>
}

// Generic API client
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'

interface EndpointConfig<TRequest, TResponse> {
  path: string
  method: HttpMethod
  requestSchema: z.ZodSchema<TRequest>
  responseSchema: z.ZodSchema<TResponse>
}

// Usage
const getUserConfig: EndpointConfig<{ id: string }, User> = {
  path: '/users/:id',
  method: 'GET',
  requestSchema: z.object({ id: z.string() }),
  responseSchema: UserSchema
}
```

### State Management (Redux/Zustand Pattern)

```typescript
// Actions
type Action =
  | { type: 'USER_LOGIN'; payload: { email: string; password: string } }
  | { type: 'USER_LOGIN_SUCCESS'; payload: User }
  | { type: 'USER_LOGIN_FAILURE'; payload: string }
  | { type: 'USER_LOGOUT' }

// State
type State = {
  user: User | null
  isLoading: boolean
  error: string | null
}

// Reducer with exhaustive switch
function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'USER_LOGIN':
      return { ...state, isLoading: true, error: null }
    case 'USER_LOGIN_SUCCESS':
      return { ...state, user: action.payload, isLoading: false }
    case 'USER_LOGIN_FAILURE':
      return { ...state, error: action.payload, isLoading: false }
    case 'USER_LOGOUT':
      return { ...state, user: null }
    default:
      const _exhaustive: never = action
      return state
  }
}
```

### Repository Pattern

```typescript
interface Repository<T, TCreate, TUpdate> {
  findAll(): Promise<T[]>
  findById(id: string): Promise<T | null>
  create(data: TCreate): Promise<T>
  update(id: string, data: TUpdate): Promise<T>
  delete(id: string): Promise<void>
}

// Implementation for User
type CreateUserDTO = Omit<User, 'id' | 'createdAt'>
type UpdateUserDTO = Partial<CreateUserDTO>

class UserRepository implements Repository<User, CreateUserDTO, UpdateUserDTO> {
  // Implementation
}
```

### Event Emitter (Type-Safe)

```typescript
type EventMap = {
  'user:login': { userId: string; timestamp: Date }
  'user:logout': { userId: string }
  'error': { message: string; code: number }
}

class TypedEmitter<Events extends Record<string, any>> {
  private listeners: { [K in keyof Events]?: Array<(payload: Events[K]) => void> } = {}

  on<K extends keyof Events>(event: K, callback: (payload: Events[K]) => void) {
    if (!this.listeners[event]) this.listeners[event] = []
    this.listeners[event]!.push(callback)
  }

  emit<K extends keyof Events>(event: K, payload: Events[K]) {
    this.listeners[event]?.forEach(cb => cb(payload))
  }
}

// Usage
const emitter = new TypedEmitter<EventMap>()
emitter.on('user:login', ({ userId, timestamp }) => {
  // userId and timestamp are typed!
})
emitter.emit('user:login', { userId: '123', timestamp: new Date() })
```

---

## Configuration Reference

### tsconfig.json by Environment

**Library/Package:**
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

**Node.js Application:**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./build",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "allowSyntheticDefaultImports": true
  }
}
```

**Frontend (React/Vite):**
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "allowImportingTsExtensions": true
  }
}
```

### Compiler Flags Explained

| Flag | Purpose | When to Use |
|------|---------|-------------|
| `strict` | Enables all strict type-checking | Always |
| `noImplicitAny` | Error on implicit any | Always |
| `strictNullChecks` | null/undefined are separate types | Always |
| `noUncheckedIndexedAccess` | Index access returns T \| undefined | For safety |
| `exactOptionalPropertyTypes` | `undefined` ≠ missing property | For APIs |
| `noImplicitReturns` | All code paths must return | For functions |
| `noFallthroughCasesInSwitch` | Prevent switch fallthrough | For safety |

---

## Migration Strategies

### JavaScript to TypeScript

**Phase 1: Setup (Week 1)**
1. Rename `.js` → `.ts` (allowJs: true)
2. Install `@types/*` packages
3. Configure tsconfig with `strict: false` initially
4. Fix only critical errors

**Phase 2: Gradual Typing (Weeks 2-4)**
1. Add types to public APIs
2. Type critical business logic
3. Enable `noImplicitAny`
4. Add type annotations to function parameters

**Phase 3: Strict Mode (Weeks 5-8)**
1. Enable `strict: true`
2. Fix all null/undefined issues
3. Add explicit return types
4. Remove all `any` types

**Phase 4: Advanced (Ongoing)**
1. Add branded types
2. Implement strict unions
3. Type tests with `vitest` or `jest`
4. Add runtime validation (Zod/io-ts)

### Incremental Adoption in Large Codebase

```typescript
// Use ts-nocheck for files not yet migrated
// @ts-nocheck

// Or ts-ignore for specific lines
// @ts-ignore - Will be typed in migration phase 2
const legacyData = window.someGlobal

// Use // @ts-expect-error when you KNOW it should error
// @ts-expect-error - Testing error handling
parseInvalidJSON("not json")
```

---

## Testing Types

```typescript
// Compile-time type tests
import { expectType } from 'tsd'

// Test that function returns correct type
expectType<string>(getUserName())

// Test that function accepts specific types
expectAssignable<{ name: string }>({ name: 'John', age: 30 })

// Test that type is never (exhaustiveness)
expectType<never>(assertNever(value))
```

---

## Common Gotchas

**1. Excess Property Checks:**
```typescript
interface User { name: string }
const user: User = { name: 'John', age: 30 } // ❌ Error: age not in User
const user2 = { name: 'John', age: 30 }
const user3: User = user2 // ✅ No error (structural typing)
```

**2. Type Widening:**
```typescript
let status = 'loading' // widened to string
const status2 = 'loading' as const // literal type 'loading'
```

**3. Array Mutability:**
```typescript
const arr: readonly string[] = ['a', 'b']
arr.push('c') // ❌ Error
```

**4. Enum vs Union:**
```typescript
// Prefer string unions over enums
// ✅ Better
 type Status = 'pending' | 'active' | 'inactive'
// ❌ Avoid
 enum Status { Pending, Active, Inactive }
```

**5. Optional Chaining vs Nullish Coalescing:**
```typescript
const name = user?.profile?.name ?? 'Anonymous'
// ?. stops at null/undefined
// ?? uses default only for null/undefined (not 0 or '')
```