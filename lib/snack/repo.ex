defmodule Arango.Repo do
  defmacro __using__(opts) do
    quote do
      alias Ecto.Changeset
      alias Ecto.Changeset.Relation

      @otp_app unquote(Keyword.get(opts, :otp_app))
      @collections unquote(Keyword.get(opts, :collections))


      def child_spec(opts \\ []) do
        opts
        |> config()
        |> Arangox.child_spec()
      end

      def config(opts \\ []) do
        Application.get_env(@otp_app, __MODULE__, [])
        |> Keyword.merge(opts)
        |> Keyword.merge(otp_app: @otp_app, name: __MODULE__)
      end
      defp handle_status(status) do
        case status do
          400 ->
            :unprocessable_entity

          404 ->
            :not_found

          409 ->
            :conflict
        end
      end

      def get_dynamic_repo do __MODULE__ end
      # new

      def insert(struct, opts \\ []) do
        Arango.Ecto.Repo.Schema.insert(@otp_app, get_dynamic_repo(), struct, with_default_options(:insert, opts))
      end

      def update(struct, opts \\ []) do
        Arango.Ecto.Repo.Schema.update(@otp_app, get_dynamic_repo(), struct, with_default_options(:update, opts))
      end

      # def insert_or_update(changeset, opts \\ []) do
      #   Ecto.Repo.Schema.insert_or_update(__MODULE__, get_dynamic_repo(), changeset, with_default_options(:insert_or_update, opts))
      # end

      def delete(struct, opts \\ []) do
        Arango.Ecto.Repo.Schema.delete(@otp_app, get_dynamic_repo(), struct, with_default_options(:delete, opts))
      end

      def insert!(struct, opts \\ []) do
        Arango.Ecto.Repo.Schema.insert!(@otp_app, get_dynamic_repo(), struct, with_default_options(:insert, opts))
      end

      def update!(struct, opts \\ []) do
        Arango.Ecto.Repo.Schema.update!(@otp_app, get_dynamic_repo(), struct, with_default_options(:update, opts))
      end

      # def insert_or_update!(changeset, opts \\ []) do
      #   Ecto.Repo.Schema.insert_or_update!(__MODULE__, get_dynamic_repo(), changeset, with_default_options(:insert_or_update, opts))
      # end

      def delete!(struct, opts \\ []) do
        Arango.Ecto.Repo.Schema.delete!(@otp_app, get_dynamic_repo(), struct, with_default_options(:delete, opts))
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        Arango.Ecto.Repo.Schema.insert_all(@otp_app, get_dynamic_repo(), schema_or_source, entries, with_default_options(:insert_all, opts))
      end




      # end


      def default_options(_operation), do: []
      defoverridable default_options: 1
      defp with_default_options(operation_name, opts) do
        Keyword.merge(default_options(operation_name), opts)
      end
      # defp put_repo_and_action(%{action: :ignore, valid?: valid?} = changeset, action, repo, opts) do
      #   if valid? do
      #     raise ArgumentError, "a valid changeset with action :ignore was given to " <>
      #                          "#{inspect repo}.#{action}/2. Changesets can only be ignored " <>
      #                          "in a repository action if they are also invalid"
      #   else
      #     %{changeset | action: action, repo: repo, repo_opts: opts}
      #   end
      # end
      # defp put_repo_and_action(%{action: given}, action, repo, _opts) when given != nil and given != action,
      #      do: raise ArgumentError, "a changeset with action #{inspect given} was given to #{inspect repo}.#{action}/2"
      # defp put_repo_and_action(changeset, action, repo, opts),
      #      do: %{changeset | action: action, repo: repo, repo_opts: opts}

      defp struct_from_changeset!(action, %{data: nil}),
           do: raise(ArgumentError, "cannot #{action} a changeset without :data")
      defp struct_from_changeset!(_action, %{data: struct}),
           do: struct

      def all(struct) do
        # {:ok, items} =
        all(struct, """
          FOR doc IN #{collection(struct)}
          RETURN doc
        """)
      end
      def all(struct, except: unset) do
        # {:ok, items} =
        all(struct, """
          FOR doc IN #{collection(struct)}
          RETURN UNSET(doc, #{Kernel.inspect unset})
        """)
      end
      def all(struct, only: only) do
        # only => ['filed1', 'filed12']
        # {:ok, items} =
        all(struct, """
          FOR doc IN #{collection(struct)}
          RETURN {#{Enum.map(only, fn(item) -> "#{item}: doc.#{item}" end) |> Enum.join(", ")}}
        """)
      end
      def all(struct_, query_string) do
        {:ok, data} =
          Arangox.transaction(
            __MODULE__,
            fn cursor ->
              stream = Arangox.cursor(cursor, query_string)
              Enum.reduce(stream, [],
                fn resp, acc ->
                  acc ++ Enum.reduce(to_struct_all(struct_, resp.body["result"]), [],
                    fn(data, acc) ->
                       [Arango.Ecto.Repo.Schema.load(Arango.Ecto.Adapter, struct_.__struct__.__struct__, Map.to_list(data)) | acc]
                    end)
                end) |> Enum.reverse
            end,
            write: @collections
          )
          data
      end
      def get(struct_, id, _opts \\ []) do
        case Arangox.get(__MODULE__, "/_api/document/#{collection(struct_)}/#{id}") do
          {:ok, _, %{body: body}} ->

            # struct_.__struct__.__struct__.__changeset__
            # struct_.__struct__.__struct__

            {:ok, Arango.Ecto.Repo.Schema.load(Arango.Ecto.Adapter,
             struct_.__struct__.__struct__,
              Map.to_list(to_struct(struct_, body))
            )}

          {:error, %{status: status}} ->
            {:error, handle_status(status)}
        end
      end
      def get!(struct_, id, _opts \\ []) do
        case Arangox.get!(__MODULE__, "/_api/document/#{collection(struct_)}/#{id}") do
          %{body: body} ->
            # struct_.__struct__.__struct__.__changeset__
            # struct_.__struct__.__struct__

            Arango.Ecto.Repo.Schema.load(Arango.Ecto.Adapter,
             struct_.__struct__.__struct__,
              Map.to_list(to_struct(struct_, body))
            )
        end
      end

      def proccess_opts(item_name, opts \\ []) do
        Enum.reduce(opts, "#{item_name}", fn({key, values}, acc) ->
          case key do
            :only ->
              "KEEP(#{item_name}, #{Kernel.inspect(values |> Enum.map(fn(item) -> Atom.to_string item end))})"
            :except ->
              "UNSET(#{item_name}, #{Kernel.inspect(values |> Enum.map(fn(item) -> Atom.to_string item end))})"
            _ -> acc
          end
        end)
      end

      # def fetch_or_insert(struct, unique_index) do
      #   fetch_or_insert(struct, unique_index, [])
      # end
      # def fetch_or_insert(struct, unique_index_atom, opts) when is_atom(unique_index_atom) do
      #   fetch_or_insert(struct, [unique_index_atom], opts)
      # end
      # def fetch_or_insert(struct, unique_index_string, opts) when is_binary(unique_index_string) do
      #   fetch_or_insert(struct, [unique_index_string], opts)
      # end
      # def fetch_or_insert(%Changeset{} = changeset, unique_index, opts) when is_list(opts) do
      #   do_fetch_or_insert(changeset, unique_index, opts)
      # end
      #
      # def fetch_or_insert(%{__struct__: _} = struct, unique_index, opts) when is_list(opts) do
      #   do_fetch_or_insert(Ecto.Changeset.change(struct), unique_index, opts)
      # end


      def prepare_changeset_for_insert(changeset, opts \\ []) do
        Arango.Ecto.Repo.Schema.prepare_changeset_for_insert(@otp_app, changeset, opts)
      end

      def prepare_changeset_keep_virtual(changeset, opts \\ []) do
        Arango.Ecto.Repo.Schema.prepare_changeset_keep_virtual(@otp_app, changeset, opts)
      end

      #
      # defp do_fetch_or_insert(%Changeset{valid?: true} = changeset, unique_index, opts) do
      #   struct_ = struct_from_changeset!(:insert, changeset)
      #   schema = struct_.__struct__
      #   dumper = schema.__schema__(:dump)
      #   fields = schema.__schema__(:fields)
      #   assocs = schema.__schema__(:associations)
      #   embeds = schema.__schema__(:embeds)
      #   collection_ = changeset.data.__meta__.source
      #
      #   changeset = put_repo_and_action(changeset, :insert, @otp_app, opts)
      #   changeset = Relation.surface_changes(changeset, struct_, fields ++ assocs)
      #   document = changeset.changes
      #   document = if document[:_key] == nil do Map.put(Map.take(document, fields), :_key, document[:id]) else Map.take(document, fields) end
      #
      #   unique_index_string = Enum.reduce(unique_index, "", fn(item, acc)->
      #     {item_atom, item_string} = if is_atom(item) do {item, Atom.to_string item} else {:"#{item}", item} end
      #     phrase = "item.#{item_string} == #{Jason.encode! changeset.changes[item_atom]}"
      #     if acc == "" do phrase else "#{acc} and #{phrase}" end
      #   end)
      #
      #   query = proccess_opts("query[0]", opts)
      #   inserted = proccess_opts("inserted[0]", opts)
      #
      #   query_string = """
      #     LET query = (FOR item in #{collection_} Filter #{unique_index_string} return item)
      #     LET inserted = (Insert #{Jason.encode! document} into #{collection_} OPTIONS { ignoreErrors: true } return NEW)
      #     return inserted == [] ? #{query} : #{inserted}
      #   """
      #
      #
      #   case Arangox.transaction(
      #     __MODULE__,
      #     fn cursor ->
      #       stream = Arangox.cursor(cursor, query_string)
      #
      #       Enum.reduce(stream, [], fn resp, acc ->
      #         acc ++ resp.body["result"]
      #       end)
      #     end,
      #     write: @collections
      #   ) do
      #     {:ok, [data]} -> {:ok, to_struct(struct_, data)}
      #     {:error, %{status: status}} -> {:error, handle_status(status)}
      #   end
      # end
      # defp do_fetch_or_insert(%Changeset{valid?: false} = changeset, unique_index, opts) do
      #   {:error, put_repo_and_action(changeset, :insert, @otp_app, opts)}
      # end


      #
      # def insert!(struct, opts \\ []) do
      #   do_insert!(struct, with_default_options(:insert, opts))
      # end
      # def do_insert!(struct_or_changeset, opts) do
      #   case insert(struct_or_changeset, opts) do
      #     {:ok, struct_} ->
      #       struct_
      #
      #     {:error, changeset} ->
      #       raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
      #   end
      # end
      #
      # def insert(struct)do
      #   insert(struct, [])
      # end
      # def insert(%Changeset{} = changeset, opts) when is_list(opts) do
      #   do_insert(changeset, opts)
      # end
      #
      # def insert(%{__struct__: _} = struct, opts) when is_list(opts) do
      #   do_insert(Ecto.Changeset.change(struct), opts)
      # end
      #
      # defp do_insert(%Changeset{valid?: true} = changeset, opts) do
      #   struct_ = struct_from_changeset!(:insert, changeset)
      #   schema = struct_.__struct__
      #   dumper = schema.__schema__(:dump)
      #   fields = schema.__schema__(:fields)
      #   assocs = schema.__schema__(:associations)
      #   embeds = schema.__schema__(:embeds)
      #
      #   changeset = put_repo_and_action(changeset, :insert, @otp_app, opts)
      #   changeset = Relation.surface_changes(changeset, struct_, fields ++ assocs)
      #   document = changeset.changes
      #
      #   case Arangox.post(
      #         __MODULE__,
      #         "/_api/document/#{collection(changeset)}?returnNew=true",
      #         document
      #        ) do
      #     {:ok, _, %{body: body}} -> {:ok, to_struct(struct_, body["new"])}
      #     {:error, %{status: status}} -> {:error, handle_status(status)}
      #   end
      # end
      # defp do_insert(%Changeset{valid?: false} = changeset, opts) do
      #   {:error, put_repo_and_action(changeset, :insert, @otp_app, opts)}
      # end
      #
      # def update!(struct_or_changeset) do
      #   update!(struct_or_changeset, [])
      # end
      # def update!(struct_or_changeset, opts) do
      #   case update(struct_or_changeset, opts) do
      #     {:ok, struct_} ->
      #       struct_
      #
      #     {:error, changeset} ->
      #       raise Ecto.InvalidChangesetError, action: :update, changeset: changeset
      #   end
      # end
      # def update(struct_or_changeset) do
      #   update(struct_or_changeset, [])
      # end
      # def update(%Changeset{} = changeset, opts) when is_list(opts) do
      #   do_update(changeset, opts)
      # end
      #
      # def update(%{__struct__: _}, opts) when is_list(opts) do
      #   raise ArgumentError, "giving a struct to Ecto.Repo.update/2 is not supported. " <>
      #                        "Ecto is unable to properly track changes when a struct is given, " <>
      #                        "an Ecto.Changeset must be given instead"
      # end
      #
      # defp returning(schema, opts) do
      #   case Keyword.get(opts, :returning, false) do
      #     [_ | _] = fields ->
      #       fields
      #     [] ->
      #       raise ArgumentError, ":returning expects at least one field to be given, got an empty list"
      #     true when is_nil(schema) ->
      #       raise ArgumentError, ":returning option can only be set to true if a schema is given"
      #     true ->
      #       schema.__schema__(:fields)
      #     false ->
      #       []
      #   end
      # end
      #
      # defp dump_field!(action, schema, field, type, value, adapter) do
      #   case Arango.Ecto.Type.adapter_dump(adapter, type, value) do
      #     {:ok, value} ->
      #       value
      #     :error ->
      #       raise Ecto.ChangeError,
      #             "value `#{inspect(value)}` for `#{inspect(schema)}.#{field}` " <>
      #             "in `#{action}` does not match type #{inspect type}"
      #   end
      # end
      #
      # defp dump_fields!(action, schema, kw, dumper, adapter) do
      #   for {field, value} <- kw do
      #     {alias, type} = Map.fetch!(dumper, field)
      #     {alias, dump_field!(action, schema, field, type, value, adapter)}
      #   end
      # end
      #
      # defp dump_changes!(action, changes, schema, extra, dumper, adapter) do
      #   autogen = autogenerate_changes(schema, action, changes)
      #   dumped =
      #     dump_fields!(action, schema, changes, dumper, adapter) ++
      #     dump_fields!(action, schema, autogen, dumper, adapter) ++
      #     extra
      #   {dumped, autogen}
      # end
      #
      # defp autogenerate_changes(schema, action, changes) do
      #   autogen_fields = action |> action_to_auto() |> schema.__schema__()
      #
      #   Enum.flat_map(autogen_fields, fn {fields, {mod, fun, args}} ->
      #     case Enum.reject(fields, &Map.has_key?(changes, &1)) do
      #       [] ->
      #         []
      #
      #       fields ->
      #         generated = apply(mod, fun, args)
      #         Enum.map(fields, &{&1, generated})
      #     end
      #   end)
      # end
      #
      # defp action_to_auto(:insert), do: :autogenerate
      # defp action_to_auto(:update), do: :autoupdate
      #
      #
      # defp add_read_after_writes([], schema),
      #   do: schema.__schema__(:read_after_writes)
      #
      # defp add_read_after_writes(return, schema),
      #   do: Enum.uniq(return ++ schema.__schema__(:read_after_writes))
      #
      # defp fields_to_sources(fields, nil) do
      #   {fields, fields}
      # end
      # defp fields_to_sources(fields, dumper) do
      #   Enum.reduce(fields, {[], []}, fn field, {types, sources} ->
      #     {source, type} = Map.fetch!(dumper, field)
      #     {[{field, type} | types], [source | sources]}
      #   end)
      # end
      # defp metadata(schema, prefix, source, autogen_id, context, opts) do
      #   %{
      #     autogenerate_id: autogen_id,
      #     context: context,
      #     schema: schema,
      #     source: source,
      #     prefix: Keyword.get(opts, :prefix, prefix)
      #   }
      # end
      # defp metadata(%{__struct__: schema, __meta__: %{context: context, source: source, prefix: prefix}},
      #               autogen_id, opts) do
      #   metadata(schema, prefix, source, autogen_id, context, opts)
      # end
      # defp metadata(%{__struct__: schema}, _, _) do
      #   raise ArgumentError, "#{inspect(schema)} needs to be a schema with source"
      # end
      #
      # defp load_changes(changeset, state, types, values, embeds, autogen, adapter, schema_meta) do
      #   %{data: data, changes: changes} = changeset
      #   data =
      #     data
      #     |> merge_changes(changes)
      #     |> Map.merge(embeds)
      #     |> merge_autogen(autogen)
      #     |> apply_metadata(state, schema_meta)
      #     |> load_each(values, types, adapter)
      #
      #   Map.put(changeset, :data, data)
      # end
      #
      # defp merge_changes(data, changes) do
      #   changes =
      #     Enum.reduce(changes, changes, fn {key, _value}, changes ->
      #       if Map.has_key?(data, key), do: changes, else: Map.delete(changes, key)
      #     end)
      #
      #   Map.merge(data, changes)
      # end
      #
      # defp merge_autogen(data, autogen) do
      #   Enum.reduce(autogen, data, fn {k, v}, acc -> %{acc | k => v} end)
      # end
      #
      # defp apply_metadata(%{__meta__: meta} = data, state, %{source: source, prefix: prefix}) do
      #   %{data | __meta__: %{meta | state: state, source: source, prefix: prefix}}
      # end
      #
      # defp load_each(struct, values, [{key, type} | types], adapter) do
      #   value = Map.get(values, key)
      #   case Arango.Ecto.Type.adapter_load(adapter, type, value) do
      #     {:ok, value} ->
      #       load_each(%{struct | key => value}, values, types, adapter)
      #     :error ->
      #       raise ArgumentError, "cannot load `#{inspect value}` as type #{inspect type} " <>
      #                            "for field `#{key}` in schema #{inspect struct.__struct__}"
      #   end
      # end
      # defp load_each(struct, _, [], _adapter) do
      #   struct
      # end
      # defp add_pk_filter!(filters, struct) do
      #   Enum.reduce Ecto.primary_key!(struct), filters, fn
      #     {_k, nil}, _acc ->
      #       raise Ecto.NoPrimaryKeyValueError, struct: struct
      #     {k, v}, acc ->
      #       Map.put(acc, k, v)
      #   end
      # end
      # defp run_prepare(changeset, prepare) do
      #   Enum.reduce(Enum.reverse(prepare), changeset, fn fun, acc ->
      #     case fun.(acc) do
      #       %Ecto.Changeset{} = acc ->
      #         acc
      #
      #       other ->
      #         raise "expected function #{inspect fun} given to Ecto.Changeset.prepare_changes/2 " <>
      #               "to return an Ecto.Changeset, got: `#{inspect other}`"
      #     end
      #   end)
      # end
      #
      #
      # defp do_update(%Changeset{valid?: true} = changeset, opts) do
      #
      #   # {adapter, adapter_meta} = Ecto.Repo.Registry.lookup(name)
      #   adapter = Arango.Ecto.Adapter
      #
      #   %{prepare: prepare, repo_opts: repo_opts} = changeset
      #   opts = Keyword.merge(repo_opts, opts)
      #
      #   struct_ = struct_from_changeset!(:update, changeset)
      #   schema = struct_.__struct__
      #   dumper = schema.__schema__(:dump)
      #   fields = schema.__schema__(:fields)
      #   assocs = schema.__schema__(:associations)
      #   embeds = schema.__schema__(:embeds)
      #
      #   force? = !!opts[:force]
      #   # filters = add_pk_filter!(changeset.filters, struct_) # new
      #
      #   {return_types, return_sources} =
      #     fields
      #     |> add_read_after_writes(schema)
      #     |> fields_to_sources(dumper)
      #
      #
      #   # Differently from insert, update does not copy the struct
      #   # fields into the changeset. All changes must be in the
      #   # changeset before hand.
      #   changeset = put_repo_and_action(changeset, :update, @otp_app, opts)
      #
      #   if changeset.changes != %{} or force? do
      #     # assoc_opts = assoc_opts(assocs, opts)
      #     user_changeset = run_prepare(changeset, prepare)
      #
      #     {changeset, parents, children} = {changeset, [], []}
      #     # changeset = process_parents(changeset, user_changeset, parents, adapter, assoc_opts)
      #     # changeset = process_parents(changeset, user_changeset, parents, adapter)
      #
      #     if changeset.valid? do
      #       embeds = Ecto.Embedded.prepare(changeset, embeds, adapter, :update)
      #
      #       original = changeset.changes |> Map.merge(embeds) |> Map.take(fields)
      #       {changes, autogen} = dump_changes!(:update, original, schema, [], dumper, adapter)
      #
      #       schema_meta = metadata(struct_, schema.__schema__(:autogenerate_id), opts)
      #       # filters = dump_fields!(:update, schema, filters, dumper, adapter)
      #       # args = [adapter_meta, schema_meta, changes, filters, return_sources, opts]
      #
      #       # If there are no changes or all the changes were autogenerated but not forced, we skip
      #       {action, autogen} =
      #         if original != %{} or (autogen != [] and force?),
      #            do: {:update, autogen},
      #            else: {:noop, []}
      #
      #      document = changeset.changes
      #      document = if document[:_key] == nil do Map.put(Map.take(document, fields), :_key, document[:id]) else Map.take(document, fields) end
      #      document = Map.new(changes)
      #
      #     case Arangox.patch(
      #            __MODULE__,
      #            "/_api/document/#{collection(changeset)}/#{document._key}?returnNew=true&keepNull=false",
      #            document
      #          ) do
      #       {:ok, _, %{body: body}} -> #x {:ok, to_struct(struct_, body["new"])}
      #         {:ok, load_changes(changeset, :loaded, return_types, to_struct(struct_, body["new"]), embeds, autogen, Arango.Ecto.Adapter, schema_meta)}
      #
      #       {:error, %{status: status}} -> {:error, handle_status(status)}
      #     end
      #   else
      #     {:ok, changeset.data}
      #   end
      # end
      # end
      #
      # defp do_update(%Changeset{valid?: false} = changeset, opts) do
      #   {:error, put_repo_and_action(changeset, :update, @otp_app, opts)}
      # end
      #
      # def delete!(struct_or_changeset) do
      #   delete!(struct_or_changeset, [])
      # end
      # def delete!(struct_or_changeset, opts) do
      #   case delete(struct_or_changeset, opts) do
      #     {:ok, struct} ->
      #       struct
      #
      #     {:error, changeset} ->
      #       raise Ecto.InvalidChangesetError, action: :delete, changeset: changeset
      #   end
      # end
      # def delete(struct_or_changeset) do
      #   delete(struct_or_changeset, [])
      # end
      # def delete(%Changeset{} = changeset, opts) when is_list(opts) do
      #   do_delete(changeset, opts)
      # end
      #
      # def delete(%{__struct__: _} = struct, opts) when is_list(opts) do
      #   changeset = Ecto.Changeset.change(struct)
      #   do_delete(changeset, opts)
      # end
      #
      # defp do_delete(%Changeset{valid?: true} = changeset, opts) do
      #   struct = struct_from_changeset!(:insert, changeset)
      #   schema = struct.__struct__
      #   dumper = schema.__schema__(:dump)
      #   fields = schema.__schema__(:fields)
      #   assocs = schema.__schema__(:associations)
      #   embeds = schema.__schema__(:embeds)
      #
      #   changeset = put_repo_and_action(changeset, :insert, @otp_app, opts)
      #   changeset = Relation.surface_changes(changeset, struct, fields ++ assocs)
      #   document = changeset.changes
      #   document = if document[:_key] == nil do Map.put(Map.take(document, fields), :_key, document[:id]) else Map.take(document, fields) end
      #
      #   if changeset.valid? do
      #     case Arangox.delete(__MODULE__, "/_api/document/#{collection(changeset)}/#{document._key}") do
      #       {:ok, _, body} -> {:ok, body}
      #       {:error, %{status: status}} -> {:error, handle_status(status)}
      #     end
      #   else
      #     {:error, changeset}
      #   end
      # end
      #
      # defp do_delete(%Changeset{valid?: false} = changeset, opts) do
      #   {:error, put_repo_and_action(changeset, :delete, @otp_app, opts)}
      # end
      # def to_struct_all(struct_, items) do
      #   to_struct(struct_, items)
      # end
      # def to_struct(struct_, items) when is_list(items) do
      #   Enum.map(items, fn(item) -> to_struct(struct_, item) end)
      # end
      # def to_struct(struct_, item) when is_map(item) do
      #   struct(struct_, string_map_to_atom(item))
      # end
      # def to_struct(struct_, item) when is_nil(item) do
      #   nil
      # end
      # def string_map_to_atom(item) when is_map(item) do
      #   id = item["_key"]
      #   item = if id == nil do item else Map.put(item, "id", id) end
      #   for {key, val} <- item, into: %{}, do: {String.to_atom(key), string_map_to_atom(val)}
      # end
      # def string_map_to_atom(items) when is_list(items) do
      #   Enum.map(items, fn(item) -> string_map_to_atom(item) end)
      # end
      # def string_map_to_atom(val) do
      #   val
      # end
      @doc """
        Similar to one/1 but raises Ecto.NoResultsError if no record was found.
        Raises if more than one entry.

        Examples
        Repo.one(
            FOR user IN users
            FILTER user.username == "some_username"
            RETURN {password: user.password, username: user.username}
        )

      """
      def one!(struct_, query_string) do
        to_struct(struct_, one!(query_string))
      end
      def one!(query_string) do
        case one(query_string) do
          nil -> raise Ecto.NoResultsError, queryable: query_string
          data -> data
        end
      end
      @doc """
        Fetches a single result from the query.

        Returns nil if no result was found. Raises if more than one entry.

        Examples
        Repo.one(
            FOR user IN users
            FILTER user.username == "some_username"
            RETURN {password: user.password, username: user.username}
        )

      """
      def one(struct_, query_string) do
        Arango.Ecto.Repo.Schema.load(
          Arango.Ecto.Adapter,
          struct_.__struct__.__struct__,
          Map.to_list(to_struct(struct_, do_one(query_string)))
        )
      end
      def one(query_string) do
        string_map_to_atom(do_one(query_string))
      end
      def do_one(query_string) do
        case Arangox.transaction(
            __MODULE__,
            fn cursor ->
              stream = Arangox.cursor(cursor, query_string)

              Enum.reduce(stream, [], fn resp, acc -> acc ++ resp.body["result"]
              end)
            end,
            write: @collections) do

            {:ok, [data]} -> data
            {:ok, []} -> nil
            {:ok, other} -> raise Ecto.MultipleResultsError, queryable: query_string, count: length(other)

          end
      end

      def query(struct_, query_string) do
        to_struct(struct_, do_query(query_string))
        |>  Enum.reduce([], fn(data, acc) ->
              [Arango.Ecto.Repo.Schema.load(Arango.Ecto.Adapter, struct_.__struct__.__struct__, Map.to_list(data)) | acc]
            end)
        |> Enum.reverse
      end
      def query(query_string) do
        string_map_to_atom(do_query(query_string))
      end
      def do_query(query_string) do
        {:ok, data} =
          Arangox.transaction(
            __MODULE__,
            fn cursor ->
              stream = Arangox.cursor(cursor, query_string)

              Enum.reduce(stream, [], fn resp, acc ->
                acc ++ resp.body["result"]
              end)
            end,
            write: @collections
          )

        {:ok, data}
        data
      end
      # def query_all(query_string) do
      #   case Arangox.transaction(
      #         __MODULE__,
      #         fn cursor ->
      #           stream = Arangox.cursor(cursor, query_string)
      #
      #           Enum.reduce(stream, [], fn resp, acc ->
      #             acc ++ resp.body["extra"]["stats"]["writesExecuted"]
      #           end)
      #         end,
      #         write: @collections
      #       ) do
      #     {:ok, result} ->
      #       {:ok, result}
      #   end
      # end

      defp document_changes(struct) do
        struct
        |> Map.from_struct()
        |> Map.get(:changes)
      end

      def to_struct_all(struct_, items) do
        to_struct(struct_, items)
      end
      def to_struct(struct_, items) when is_list(items) do
        Enum.map(items, fn(item) -> to_struct(struct_, item) end)
      end
      def to_struct(struct_, item) when is_map(item) do
        struct(struct_, string_map_to_atom(item))
      end
      def to_struct(struct_, item) when is_nil(item) do
        nil
      end
      def string_map_to_atom(item) when is_map(item) do
        id = item["_key"]
        item = if id == nil do item else Map.put(item, "id", id) end
        for {key, val} <- item, into: %{}, do: {String.to_atom(key), string_map_to_atom(val)}
      end
      def string_map_to_atom(items) when is_list(items) do
        Enum.map(items, fn(item) -> string_map_to_atom(item) end)
      end
      def string_map_to_atom(val) do
        val
      end

      def collection(%Ecto.Changeset{} = struct), do: struct.data.__meta__.source
      def collection(struct), do: struct.__struct__.__meta__.source
    end
  end
end
