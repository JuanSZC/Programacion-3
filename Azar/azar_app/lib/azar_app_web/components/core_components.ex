defmodule AzarAppWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component
  use Gettext, backend: AzarAppWeb.Gettext
  alias Phoenix.LiveView.JS

  # ---------------------------------------------------------------------------
  # FLASH
  # ---------------------------------------------------------------------------

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error, :success, :warning]
  attr :rest, :global
  slot :inner_block

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
        "flex items-start gap-3 w-80 px-4 py-3.5 rounded-2xl cursor-pointer",
        "backdrop-blur-sm transition-all duration-200 hover:opacity-80"
      ]}
      style={case @kind do
        :info    -> "background:var(--bg-elevated);border:1px solid var(--border);color:var(--text-primary)"
        :success -> "background:var(--mint-dim);border:1px solid rgba(16,185,129,.2);color:#6EE7B7"
        :error   -> "background:var(--rose-dim);border:1px solid rgba(244,63,94,.2);color:#FDA4AF"
        :warning -> "background:var(--amber-dim);border:1px solid rgba(245,158,11,.2);color:#FCD34D"
      end}>
        <div class="shrink-0 w-8 h-8 rounded-xl flex items-center justify-center mt-0.5"
          style={case @kind do
            :info    -> "background:var(--indigo-dim);color:var(--indigo-light)"
            :success -> "background:var(--mint-dim);color:var(--mint)"
            :error   -> "background:var(--rose-dim);color:var(--rose)"
            :warning -> "background:var(--amber-dim);color:var(--amber)"
          end}>
          <.icon :if={@kind == :info}    name="hero-information-circle-solid" class="size-4" />
          <.icon :if={@kind == :success} name="hero-check-circle-solid"       class="size-4" />
          <.icon :if={@kind == :error}   name="hero-exclamation-circle-solid" class="size-4" />
          <.icon :if={@kind == :warning} name="hero-exclamation-triangle-solid" class="size-4" />
        </div>
        <div class="flex-1 min-w-0">
          <p :if={@title} class="font-semibold text-sm leading-tight mb-0.5">{@title}</p>
          <p class="text-sm opacity-80 leading-snug">{msg}</p>
        </div>
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

  def button(%{rest: rest} = assigns) do
    style_map = %{
      "primary"   => "background:var(--indigo);color:white;border:none",
      "secondary" => "background:var(--bg-card);color:var(--text-secondary);border:1px solid var(--border)",
      "danger"    => "background:var(--rose-dim);color:var(--rose);border:1px solid rgba(244,63,94,.2)",
      "ghost"     => "background:transparent;color:var(--text-secondary);border:none",
      "outline"   => "background:transparent;color:var(--text-secondary);border:1px solid var(--border)",
      "default"   => "background:var(--bg-card);color:var(--text-primary);border:1px solid var(--border)"
    }

    assigns = assign_new(assigns, :btn_style, fn ->
      Map.get(style_map, assigns[:variant], style_map["primary"])
    end)

    assigns = assign_new(assigns, :combined_class, fn ->
      [
        "inline-flex items-center gap-2 px-4 h-9 text-sm font-semibold",
        "rounded-xl transition-all duration-150 active:scale-[0.98]",
        assigns[:class]
      ]
    end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@combined_class} style={@btn_style} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@combined_class} style={@btn_style} {@rest}>
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
  attr :field, Phoenix.HTML.FormField
  attr :errors, :list, default: []
  attr :checked, :boolean
  attr :prompt, :string, default: nil
  attr :options, :list
  attr :multiple, :boolean, default: false
  attr :class, :any, default: nil
  attr :error_class, :any, default: nil
  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength multiple pattern placeholder readonly required rows size step)

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
      <input type="checkbox" id={@id} name={@name} value="true" checked={@checked}
        class={@class || "checkbox checkbox-primary checkbox-sm rounded-md"} {@rest} />
      <label for={@id} class="text-sm font-medium cursor-pointer select-none" style="color:var(--text-secondary)">
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5 w-full">
      <label :if={@label} for={@id}
        class="text-xs font-semibold uppercase tracking-wide"
        style="color:var(--text-muted)">
        {@label}
      </label>
      <select id={@id} name={@name}
        class={[@class || "select w-full rounded-xl text-sm h-10 min-h-0 transition-all", @errors != [] && (@error_class || "select-error")]}
        style="background:var(--bg-card);border:1px solid var(--border);color:var(--text-primary)"
        multiple={@multiple} {@rest}>
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
      <label :if={@label} for={@id}
        class="text-xs font-semibold uppercase tracking-wide"
        style="color:var(--text-muted)">
        {@label}
      </label>
      <textarea id={@id} name={@name}
        class={[@class || "textarea w-full rounded-xl text-sm min-h-[90px] transition-all resize-none", @errors != [] && (@error_class || "textarea-error")]}
        style="background:var(--bg-card);border:1px solid var(--border);color:var(--text-primary)"
        {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5 w-full">
      <label :if={@label} for={@id}
        class="text-xs font-semibold uppercase tracking-wide"
        style="color:var(--text-muted)">
        {@label}
      </label>
      <input type={@type} name={@name} id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[@class || "input w-full rounded-xl text-sm h-10 transition-all", @errors != [] && (@error_class || "input-error")]}
        style="background:var(--bg-card);border:1px solid var(--border);color:var(--text-primary)"
        {@rest} />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p class="flex items-center gap-1.5 text-xs font-medium mt-0.5" style="color:var(--rose)">
      <.icon name="hero-exclamation-circle-mini" class="size-3.5 shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ---------------------------------------------------------------------------
  # HEADER
  # ---------------------------------------------------------------------------

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class="flex items-start justify-between gap-4 pb-6">
      <div>
        <h1 class="font-display text-xl font-bold tracking-tight leading-tight" style="color:var(--text-primary)">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm mt-1 font-medium" style="color:var(--text-muted)">
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

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto rounded-2xl" style="border:1px solid var(--border)">
      <table class="w-full text-sm">
        <thead>
          <tr style="border-bottom:1px solid var(--border)">
            <th :for={col <- @col}
              class="px-5 py-3 text-left text-[10px] font-semibold uppercase tracking-widest"
              style="color:var(--text-muted);background:var(--bg-surface)">
              {col[:label]}
            </th>
            <th :if={@action != []} class="px-5 py-3 text-right" style="background:var(--bg-surface)">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody id={@id}
          phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
          class="divide-y"
          style="divide-color:var(--border)">
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)}
            class="group transition-colors duration-100"
            style="background:var(--bg-surface)"
            onmouseenter="this.style.background='var(--bg-card)'"
            onmouseleave="this.style.background='var(--bg-surface)'">
            <td :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={["px-5 py-3.5", @row_click && "cursor-pointer"]}
              style="color:var(--text-secondary)">
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
  # LIST
  # ---------------------------------------------------------------------------

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="rounded-2xl overflow-hidden" style="border:1px solid var(--border)">
      <dl class="divide-y" style="divide-color:var(--border)">
        <div :for={item <- @item}
          class="grid grid-cols-1 sm:grid-cols-3 gap-1 px-5 py-4 transition-colors"
          style="background:var(--bg-surface)"
          onmouseenter="this.style.background='var(--bg-card)'"
          onmouseleave="this.style.background='var(--bg-surface)'">
          <dt class="text-xs font-semibold uppercase tracking-wide self-center" style="color:var(--text-muted)">
            {item.title}
          </dt>
          <dd class="sm:col-span-2 text-sm font-medium" style="color:var(--text-primary)">
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

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class, "inline-block align-middle"]} />
    """
  end

  # ---------------------------------------------------------------------------
  # JS HELPERS
  # ---------------------------------------------------------------------------

  def show(js \\ %JS{}, selector) do
    JS.show(js, to: selector, time: 250,
      transition: {"transition-all ease-out duration-250", "opacity-0 translate-y-2 scale-98", "opacity-100 translate-y-0 scale-100"})
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js, to: selector, time: 200,
      transition: {"transition-all ease-in duration-200", "opacity-100 translate-y-0 scale-100", "opacity-0 translate-y-2 scale-98"})
  end

  # ---------------------------------------------------------------------------
  # I18N
  # ---------------------------------------------------------------------------

  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(AzarAppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AzarAppWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
