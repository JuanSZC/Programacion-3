defmodule AzarAppWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component
  use Gettext, backend: AzarAppWeb.Gettext

  alias Phoenix.LiveView.JS

  # ---------------------------------------------------------------------------
  # FLASH
  # ---------------------------------------------------------------------------

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom,
    values: [:info, :error, :success, :warning],
    doc: "used for styling and flash lookup"
  attr :rest, :global,
    doc: "the arbitrary HTML attributes to add to the flash container"
  slot :inner_block, doc: "the optional inner block that renders the flash message"

  @doc """
  Componente de flash — notificaciones de sistema.
  """
  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-[100] mt-2"
      {@rest}
    >
      <div class={[
        "flex items-start gap-3 w-80 px-4 py-3.5 rounded-xl border shadow-lg cursor-pointer",
        "backdrop-blur-sm transition-all duration-200 hover:opacity-80",
        @kind == :info    && "bg-base-100/95 border-base-content/10 text-base-content",
        @kind == :success && "bg-success/10 border-success/20 text-success-content",
        @kind == :error   && "bg-error/10 border-error/20 text-error",
        @kind == :warning && "bg-warning/10 border-warning/20 text-warning-content"
      ]}>
        <%!-- Ícono --%>
        <div class={[
          "shrink-0 w-8 h-8 rounded-lg flex items-center justify-center mt-0.5",
          @kind == :info    && "bg-primary/10 text-primary",
          @kind == :success && "bg-success/15 text-success",
          @kind == :error   && "bg-error/10 text-error",
          @kind == :warning && "bg-warning/15 text-warning"
        ]}>
          <.icon :if={@kind == :info}    name="hero-information-circle-solid" class="size-4" />
          <.icon :if={@kind == :success} name="hero-check-circle-solid"       class="size-4" />
          <.icon :if={@kind == :error}   name="hero-exclamation-circle-solid" class="size-4" />
          <.icon :if={@kind == :warning} name="hero-exclamation-triangle-solid" class="size-4" />
        </div>

        <%!-- Texto --%>
        <div class="flex-1 min-w-0">
          <p :if={@title} class="font-semibold text-sm leading-tight mb-0.5">{@title}</p>
          <p class="text-sm opacity-80 leading-snug">{msg}</p>
        </div>

        <%!-- Cerrar --%>
        <button type="button" class="shrink-0 mt-0.5 opacity-40 hover:opacity-70 transition-opacity" aria-label={gettext("close")}>
          <.icon name="hero-x-mark-solid" class="size-4" />
        </button>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # BUTTON
  # ---------------------------------------------------------------------------

  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any, default: nil
  attr :variant, :string, default: "primary",
    values: ~w(primary secondary danger ghost outline default)
  slot :inner_block, required: true

  @doc """
  Botón de acción con variantes.
  """
  def button(%{rest: rest} = assigns) do
    variants = %{
      "primary"   => "bg-primary text-primary-content hover:opacity-90 shadow-sm shadow-primary/20 border-transparent",
      "secondary" => "bg-secondary text-secondary-content hover:opacity-90 shadow-sm border-transparent",
      "danger"    => "bg-error text-white hover:opacity-90 shadow-sm shadow-error/20 border-transparent",
      "ghost"     => "bg-transparent text-base-content/70 hover:text-base-content hover:bg-base-content/6 border-transparent",
      "outline"   => "bg-transparent text-base-content/70 hover:text-base-content hover:bg-base-content/5 border-base-content/15",
      "default"   => "bg-base-200 text-base-content hover:bg-base-200/80 border-transparent"
    }

    assigns =
      assign_new(assigns, :combined_class, fn ->
        [
          "btn inline-flex items-center gap-2 px-4 h-9 text-sm font-semibold",
          "rounded-lg border transition-all duration-150 active:scale-[0.98]",
          Map.get(variants, assigns[:variant], variants["primary"]),
          assigns[:class]
        ]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@combined_class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@combined_class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  # ---------------------------------------------------------------------------
  # INPUT
  # ---------------------------------------------------------------------------

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text",
    values: ~w(checkbox color date datetime-local email file month number password search select tel text textarea time url week hidden)
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil
  attr :error_class, :any, default: nil
  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength multiple pattern placeholder readonly required rows size step)

  @doc """
  Componente de input unificado.
  """
  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn ->
      Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
    end)

    ~H"""
    <div class="flex items-center gap-3 py-1">
      <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} form={@rest[:form]} />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class={@class || "checkbox checkbox-primary checkbox-sm rounded-md"}
        {@rest}
      />
      <label for={@id} class="text-sm font-medium text-base-content/75 cursor-pointer select-none">
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5 w-full">
      <label :if={@label} for={@id} class="text-xs font-semibold text-base-content/60 uppercase tracking-wide">
        {@label}
      </label>
      <select
        id={@id}
        name={@name}
        class={[
          @class || "select select-bordered w-full rounded-lg bg-base-100 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary/40 transition-all h-10 min-h-0",
          @errors != [] && (@error_class || "select-error")
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="" disabled selected={@value in [nil, ""]}>{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5 w-full">
      <label :if={@label} for={@id} class="text-xs font-semibold text-base-content/60 uppercase tracking-wide">
        {@label}
      </label>
      <textarea
        id={@id}
        name={@name}
        class={[
          @class || "textarea textarea-bordered w-full rounded-lg bg-base-100 text-sm min-h-[90px] focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary/40 transition-all resize-none",
          @errors != [] && (@error_class || "textarea-error")
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5 w-full">
      <label :if={@label} for={@id} class="text-xs font-semibold text-base-content/60 uppercase tracking-wide">
        {@label}
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          @class || "input input-bordered w-full rounded-lg bg-base-100 text-sm h-10 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary/40 transition-all",
          @errors != [] && (@error_class || "input-error")
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p class="flex items-center gap-1.5 text-xs font-medium text-error mt-0.5">
      <.icon name="hero-exclamation-circle-mini" class="size-3.5 shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ---------------------------------------------------------------------------
  # HEADER DE PÁGINA
  # ---------------------------------------------------------------------------

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  @doc """
  Header de sección con título, subtítulo y acciones opcionales.
  """
  def header(assigns) do
    ~H"""
    <header class={["flex items-start justify-between gap-4 pb-6", @actions == [] && ""]}>
      <div>
        <h1 class="font-display text-xl font-bold tracking-tight text-base-content leading-tight">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/50 mt-1 font-medium">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class="flex-none flex items-center gap-2">
        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  # ---------------------------------------------------------------------------
  # TABLE
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil
  attr :row_click, :any, default: nil
  attr :row_item, :any, default: &Function.identity/1
  slot :col, required: true do
    attr :label, :string
  end
  slot :action

  @doc """
  Tabla de datos con hover y acciones por fila.
  """
  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto rounded-xl border border-base-content/8 bg-base-100">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-base-content/8">
            <th
              :for={col <- @col}
              class="px-5 py-3 text-left text-[10px] font-semibold uppercase tracking-widest text-base-content/40"
            >
              {col[:label]}
            </th>
            <th :if={@action != []} class="px-5 py-3 text-right">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
          class="divide-y divide-base-content/6"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class="group hover:bg-base-content/3 transition-colors duration-100"
          >
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={["px-5 py-3.5 text-base-content/80", @row_click && "cursor-pointer"]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="px-5 py-3.5 text-right">
              <div class="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity duration-150">
                {for action <- @action, do: render_slot(action, @row_item.(row))}
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # LIST (clave/valor)
  # ---------------------------------------------------------------------------

  slot :item, required: true do
    attr :title, :string, required: true
  end

  @doc """
  Lista de pares clave–valor para mostrar detalles de un registro.
  """
  def list(assigns) do
    ~H"""
    <div class="rounded-xl border border-base-content/8 bg-base-100 overflow-hidden">
      <dl class="divide-y divide-base-content/6">
        <div
          :for={item <- @item}
          class="grid grid-cols-1 sm:grid-cols-3 gap-1 px-5 py-4 hover:bg-base-content/2 transition-colors"
        >
          <dt class="text-xs font-semibold text-base-content/45 uppercase tracking-wide self-center">
            {item.title}
          </dt>
          <dd class="sm:col-span-2 text-sm text-base-content font-medium">
            {render_slot(item)}
          </dd>
        </div>
      </dl>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # ICON
  # ---------------------------------------------------------------------------

  attr :name, :string, required: true
  attr :class, :any, default: "size-5"

  @doc """
  Ícono de Heroicons.
  """
  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class, "inline-block align-middle"]} />
    """
  end

  # ---------------------------------------------------------------------------
  # JS HELPERS
  # ---------------------------------------------------------------------------

  @doc "Muestra un elemento con transición."
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 250,
      transition: {
        "transition-all ease-out duration-250",
        "opacity-0 translate-y-2 scale-98",
        "opacity-100 translate-y-0 scale-100"
      }
    )
  end

  @doc "Oculta un elemento con transición."
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition: {
        "transition-all ease-in duration-200",
        "opacity-100 translate-y-0 scale-100",
        "opacity-0 translate-y-2 scale-98"
      }
    )
  end

  # ---------------------------------------------------------------------------
  # I18N HELPERS
  # ---------------------------------------------------------------------------

  @doc false
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(AzarAppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AzarAppWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc false
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
