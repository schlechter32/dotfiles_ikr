# ~/.config/nvim/julials_startup.jl
# ---------------------------------------------------------------
# Julia LSP bootstrap with:
# - Correct workspace parent discovery
# - Downward nested env discovery
# - Correct hierarchical LOAD_PATH
# ---------------------------------------------------------------

# --- 1. Load LSP deps from @nvim-lspconfig
ls_install_path = joinpath(
    get(DEPOT_PATH, 1, joinpath(homedir(), ".julia")),
    "environments", "nvim-lspconfig",
)
pushfirst!(LOAD_PATH, ls_install_path)
using LanguageServer, SymbolServer, StaticLint
popfirst!(LOAD_PATH)

# --- 2. Depot + PWD
depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
pwd_path = pwd()

# --- 3. Find nearest Project.toml upwards
function find_root_project(path::AbstractString)
    while !isempty(path) && path != dirname(path)
        proj = joinpath(path, "Project.toml")
        if isfile(proj)
            return path
        end
        path = dirname(path)
    end
    return nothing
end

root_project = let
    env_proj = let p = get(ENV, "JULIA_PROJECT", nothing)
        (p === nothing || isempty(p)) ? nothing : Base.load_path_expand(p)
    end
    something(env_proj, find_root_project(pwd_path))
end

if root_project === nothing
    fallback_env = joinpath(
        get(DEPOT_PATH, 1, joinpath(homedir(), ".julia")),
        "environments", "nvim-lspconfig",
    )
    root_project = isdir(fallback_env) ? fallback_env : Base.load_path_expand("@v#.#")
    @warn "No local Project.toml found; using fallback environment" root_project
end

# --- 4. Detect parent workspace project
function find_parent_project(dir::AbstractString)
    parent = dirname(dir)
    while parent != dir
        if isfile(joinpath(parent, "Project.toml"))
            return parent
        end
        dir, parent = parent, dirname(parent)
    end
    return nothing
end

parent_project = find_parent_project(root_project)

# --- 5. Find nested child projects (downwards)
function find_nested_projects(root::AbstractString)
    nested = String[]
    for (dir, _, files) in walkdir(root)
        if "Project.toml" in files && dir != root
            push!(nested, dir)
        end
    end
    return nested
end

nested_projects =
    (isdir(root_project) ? find_nested_projects(root_project) : String[])

@info LOAD_PATH
# --- 6. Construct Julia-style hierarchical LOAD_PATH
LOAD_PATH[:] = filter(
    !isnothing, [
        root_project,
        "@v#.#",
        "@stdlib",
    ]
)
@info LOAD_PATH

for env in nested_projects
    push!(LOAD_PATH, env)
end

# --- 7. Activate primary workspace
using Pkg
Pkg.activate(root_project, io = devnull)

@info "Starting Julia LSP" VERSION pwd = pwd_path project = root_project parent = parent_project nested = nested_projects depot = depot_path load_path = LOAD_PATH

@info "root project: $root_project"
# --- 8. Run LanguageServer
server = LanguageServer.LanguageServerInstance(stdin, stdout, root_project, depot_path)
server.runlinter = true
run(server)
