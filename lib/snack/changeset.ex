defmodule Arango.Changeset do

  @relations [:embed, :assoc]
  alias Ecto.Changeset.Relation

  # def validate_list(changes, types, fields, errors, trim) do
  #   fields_with_errors = for field <- fields,
  #       (case field do
  #         {parrent, childs_field} ->
  #           childs_errors = case errors[parrent] do
  #             {_, list} -> list
  #             _ -> []
  #           end
  #           childs_fields = List.wrap(childs_field)
  #           childs_changes = changes[parrent] || %{}
  #           childs_types =  Map.new types[parrent].type
  #           validate_list(childs_changes, childs_types, childs_fields, childs_errors, trim)
  #         field ->
  #           missing?(%{data: changes}, field, trim) and
  #           ensure_field_exists!(%{data: changes, types: types}, field) and
  #           is_nil(errors[field])
  #       end), do: field
  #
  #     case fields_with_errors do
  #       [] ->
  #         %{changeset | required: fields ++ required}
  #
  #       _  ->
  #         message = message(opts, "can't be blank")
  #         new_errors = Enum.map(fields_with_errors, &{&1, {message, [validation: :required]}})
  #         changes = Map.drop(changes, fields_with_errors)
  #         %{changeset | changes: changes, required: fields ++ required, errors: new_errors ++ errors, valid?: false}
  #     end
  # end

  def fetch_childs_errors(errors, parrent) do
    if errors == [] or errors == %{} do
      []
    else
      case errors[parrent] do
        {_, list} -> list
        _ -> []
      end
    end
  end


  def validate_map_fields(childs_fields, [{key, changes} | all_changes], %{changes: main_changes, errors: errors}, main_errors, childs_types, trim, opts) do
    childs_errors = fetch_childs_errors(main_errors, key)
    %{changes: new_value, errors: new_err} =
       validate_fields(childs_fields, %{changes: changes, errors: []}, childs_errors, childs_types, trim, opts)
       # validate_fields(val, childs_types, childs_fields, childs_errors_tmp, trim, opts)

    new_changeset = %{
      changes: Map.put(main_changes, key, new_value),
      errors: if (new_err != []) do [{key, new_err} | errors] else errors end
    }
    validate_map_fields(childs_fields, all_changes, new_changeset, main_errors, childs_types, trim, opts)
  end
  def validate_map_fields(_childs_fields, [],changeset, _main_errors,_type, _trim, _opts) do
    changeset
  end
  def validate_array_fields(childs_fields, [changes | all_changes], %{changes: main_changes, errors: errors}, main_errors, childs_types, trim, opts) do
    # childs_errors = fetch_childs_errors(main_errors, key)
    %{changes: new_value, errors: new_err} =
       validate_fields(childs_fields, %{changes: changes, errors: []}, main_errors, childs_types, trim, opts)
       # validate_fields(val, childs_types, childs_fields, childs_errors_tmp, trim, opts)

    new_changeset = %{
      changes: [new_value | main_changes],
      errors: if (new_err != []) do [new_err | errors] else errors end
    }
    validate_array_fields(childs_fields, all_changes, new_changeset, main_errors, childs_types, trim, opts)
  end
  def validate_array_fields(_childs_fields, [],changeset, _main_errors,_type, _trim, _opts) do
    changeset
  end
  def validate_field({_parrent, childs_fields} = _field, {:map, type}, %{changes: childs_changes, errors: []} = _changeset, childs_errors, trim, opts) do
    childs_types = Map.new(type.type)
    childs_fields = List.wrap(childs_fields)
    # (childs_fields, %{changes: childs_changes, errors: []}, childs_errors, childs_types, trim, opts)
    validate_map_fields(childs_fields, Map.to_list(childs_changes), %{changes: childs_changes, errors: []}, childs_errors, childs_types, trim, opts)
  end
  def validate_field({_parrent, childs_fields} = _field, {:array, type}, %{changes: childs_changes, errors: []} = _changeset, childs_errors, trim, opts) do
    childs_changes = if childs_changes == %{} do [] else childs_changes end
    childs_types = Map.new(type.type)
    childs_fields = List.wrap(childs_fields)
    # (childs_fields, %{changes: childs_changes, errors: []}, childs_errors, childs_types, trim, opts)
    validate_array_fields(childs_fields, childs_changes, %{changes: [], errors: []}, childs_errors, childs_types, trim, opts)
  end
  def validate_field({_parrent, childs_fields} = _field, type, %{changes: childs_changes, errors: []} = _changeset, childs_errors, trim, opts) do
    childs_fields = List.wrap(childs_fields)
    childs_types = Map.new(type.type)
    validate_fields(childs_fields, %{changes: childs_changes, errors: []}, childs_errors, childs_types, trim, opts)
  end

  def validate_field(field, types, %{changes: changes, errors: errors} = temp_changeset, main_errors, trim, opts) do
    if (missing?(%{data: changes}, field, trim) and
        ensure_field_exists!(%{data: changes, types: types}, field) and
        is_nil(main_errors[field]))
    do
      message = message(opts, "can't be blank")
      new_error = {field, {message, [validation: :required]}}
      changes = Map.drop(changes, [field])
      %{changes: changes, errors: [new_error | errors]}
    else
      temp_changeset
    end
  end

  def validate_fields([{parrent, _childs_fields} = field | fields], %{changes: main_changes, errors: errors} = temp_changeset, main_errors, types, trim, opts) do
    childs_errors = fetch_childs_errors(main_errors, parrent)
    childs_changes = main_changes[parrent] || %{}
    %{changes: new_changes, errors: new_errors} =
      validate_field(field, types[parrent], %{changes: childs_changes, errors: []}, childs_errors, trim, opts)

    new_changeset = if new_errors != [] do
      message = message(opts, "childs can't be blank")
      new_error = {parrent, {message, new_errors}}
      changes = Map.put(main_changes, parrent, new_changes)
      %{changes: changes, errors: [new_error | errors]}
    else
      temp_changeset
    end

    validate_fields(fields, new_changeset, main_errors, types, trim, opts)
  end
  def validate_fields([field | fields], temp_changeset, main_errors, types, trim, opts) do
    new_changeset = validate_field(field, types, temp_changeset, main_errors, trim, opts)
    validate_fields(fields, new_changeset, main_errors, types, trim, opts)
  end
  def validate_fields([], changeset, _main_errors, _types, _trim, _opts) do
    changeset
  end
  def validate_required(%Ecto.Changeset{} = changeset, fields, opts \\ []) when not is_nil(fields) do
    %{required: required, errors: errors, changes: changes, types: types} = changeset
    trim = Keyword.get(opts, :trim, true)
    fields = List.wrap(fields)

    %{changes: changes, errors: new_errors} =
      validate_fields(fields, %{changes: changes, errors: []}, errors, types, trim, opts)

    case new_errors do
      [] -> %{changeset | required: fields ++ required}
      _  -> %{changeset | changes: changes, required: fields ++ required, errors: new_errors ++ errors, valid?: false}
    end
  end

  defp missing?(changeset, field, trim) when is_atom(field) do
    case get_field(changeset, field) do
      %{__struct__: Ecto.Association.NotLoaded} ->
        raise ArgumentError, "attempting to validate association `#{field}` " <>
                             "that was not loaded. Please preload your associations " <>
                             "before calling validate_required/3 or pass the :required " <>
                             "option to Ecto.Changeset.cast_assoc/3"
      value when is_binary(value) and trim -> String.trim_leading(value) == ""
      value when is_binary(value) -> value == ""
      nil -> true
      _ -> false
    end
  end

  defp missing?(_changeset, field, _trim) do
    raise ArgumentError, "validate_required/3 expects field names to be atoms, got: `#{inspect field}`"
  end

  defp ensure_field_exists!(%Ecto.Changeset{types: types, data: data}, field) do
    unless Map.has_key?(types, field) do
      raise ArgumentError, "unknown field #{inspect(field)} in #{inspect(data)}"
    end
    true
  end
  defp ensure_field_exists!(%{types: types, data: data}, field) do
    unless Map.has_key?(types, field) do
      raise ArgumentError, "unknown field #{inspect(field)} in #{inspect(data)}"
    end
    true
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end

  def get_field(data, key) do
    get_field(data, key, nil)
  end
  def get_field(%Ecto.Changeset{changes: changes, data: data, types: types}, key, default) do
    case Map.fetch(changes, key) do
      {:ok, value} ->
        change_as_field(types, key, value)
      :error ->
        case Map.fetch(data, key) do
          {:ok, value} -> data_as_field(data, types, key, value)
          :error       -> default
        end
    end
  end
  def get_field(%{data: data}, key, default) do
    case Map.fetch(data, key) do
      {:ok, value} ->
        value
      :error ->
        default
    end
  end
  defp change_as_field(types, key, value) do
    case Map.get(types, key) do
      {tag, relation} when tag in @relations ->
        Relation.apply_changes(relation, value)
      _other ->
        value
    end
  end

  defp data_as_field(data, types, key, value) do
    case Map.get(types, key) do
      {tag, _relation} when tag in @relations ->
        Relation.load!(data, value)
      _other ->
        value
    end
  end



  def validate_metadata(%{valid?: true, changes: changes} = changeset, meta_key, all_metatypes, to_validate) do
    meta_types = all_metatypes[meta_key]
    case changes[meta_key] do
      nil -> changeset
      params ->
        case Enum.reduce(to_validate,
          {%{}, meta_types}
            |> Ecto.Changeset.cast(params, Map.keys(meta_types)),
            fn(key, changeset) -> changeset |> validate_metadata_inner_map(key, all_metatypes) end) do

          %{valid?: true, changes: changes} ->
            Ecto.Changeset.put_change(changeset, meta_key, changes)

          %{valid?: false, errors: errors} ->
            Enum.reduce(errors, changeset, fn({key, { msg, additional}}, acc) ->
              Ecto.Changeset.add_error(acc, :"#{Atom.to_string meta_key}.#{key}", msg, additional)
            end)
        end
    end
  end
  def validate_metadata(changeset, _, _, _) do
    changeset
  end
  def validate_metadata_inner_map(%{valid?: true, changes: changes} = changeset, meta_key, all_metatypes) do
    meta_types = all_metatypes[meta_key]
    case changes[meta_key] do
      nil -> changeset
      params ->
        meta_changeset =
          Enum.reduce(params, %{valid?: true, errors: [], changes: %{}},
            fn({key, val}, _acc = %{valid?: valid?, errors: acc_errors, changes: acc_changes}) ->
              case val do
                nil ->
                  %{valid?: valid?, errors: acc_errors, changes: Map.put(acc_changes, key, nil)}
                val ->

                  case {%{}, meta_types}
                  |> Ecto.Changeset.cast(val, Map.keys(meta_types))
                  |> Ecto.Changeset.validate_required(Map.keys(meta_types)) do

                  %{valid?: true, changes: changes} ->
                    %{valid?: valid?, errors: acc_errors, changes: Map.put(acc_changes, key, changes)}
                  %{valid?: false, changes: changes, errors: errors} ->
                    # errors = key
                    acc_errors = Enum.reduce(errors, acc_errors, fn({err_key, err_val}, acc_errors) ->
                      [ {:"#{key}.#{err_key}", err_val} | acc_errors]
                    end)
                    %{valid?: false, errors: acc_errors, changes: Map.put(acc_changes, key, changes)}
                end

              end
          end)

        case meta_changeset do
          %{valid?: true, changes: changes} ->
            Ecto.Changeset.put_change(changeset, meta_key, changes)

          %{valid?: false, errors: errors} ->
            Enum.reduce(errors, changeset, fn({key, { msg, additional}}, acc) ->
              Ecto.Changeset.add_error(acc, :"#{Atom.to_string meta_key}.#{key}", msg, additional)
            end)
        end

    end
  end
  def validate_metadata_inner_map(changeset, _, _) do
    changeset
  end


  def validate_required_metadata(%{valid?: true, changes: changes} = changeset, meta_key, all_metatypes, to_validate) do
    meta_types = all_metatypes[meta_key]
    case changes[meta_key] do
      nil -> changeset
      params ->
        case {%{}, meta_types}
          |> Ecto.Changeset.cast(params, Map.keys(meta_types))
          |> Ecto.Changeset.validate_required(to_validate) do

            %{valid?: true, changes: changes} ->
              Ecto.Changeset.put_change(changeset, meta_key, changes)

            %{valid?: false, errors: errors} ->
              Enum.reduce(errors, changeset, fn({key, { msg, additional}}, acc) ->
                Ecto.Changeset.add_error(acc, :"#{Atom.to_string meta_key}.#{key}", msg, additional) end)
      end
    end
  end
  def validate_required_metadata(changeset, _, _, _) do
    changeset
  end
end
