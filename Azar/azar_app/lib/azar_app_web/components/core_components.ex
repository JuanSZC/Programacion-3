defmodule AzarAppWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component
  use Gettext, backend: AzarAppWeb.Gettext

  alias Phoenix.LiveView.JS

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error, :success], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-center sm:toast-end z-[100] mt-4"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap shadow-2xl rounded-2xl border-0 backdrop-blur-md cursor-pointer transition-all duration-300",
        @kind == :info && "bg-base-100/95 text-base-content border-l-4 border-l-primary",
        @kind == :success && "bg-success/90 text-success-content",
        @kind == :error && "bg-error/95 text-error-content"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-6 shrink-0 text-primary" />
        <.icon :if={@kind == :success} name="hero-check-circle" class="size-6 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-6 shrink-0" />
        <div class="flex-1">
          <p :if={@title} class="font-bold tracking-wide text-sm">{@title}</p>
          <p class="text-sm font-medium opacity-90">{msg}</p>
        </div>
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-50 group-hover:opacity-100 transition-opacity" />
        </button>
      </div>
    </div>
    """
  end

  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any, default: nil
  attr :variant, :string, default: "primary", values: ~w(primary secondary danger ghost outline default)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{
      "primary" => "btn-primary text-primary-content shadow-lg shadow-primary/30",
      "secondary" => "btn-secondary shadow-lg shadow-secondary/30",
      "danger" => "btn-error text-white shadow-lg shadow-error/30",
      "ghost" => "btn-ghost hover:bg-base-200",
      "outline" => "btn-outline border-base-300 hover:border-base-content/30",
      "default" => "btn-neutral",
      nil => "btn-primary"
    }

    assigns =
      assign_new(assigns, :combined_class, fn ->
        [
          "btn rounded-xl transition-all duration-200 active:scale-95",
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

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text", values: ~w(checkbox color date datetime-local email file month number password search select tel text textarea time url week hidden)
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
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
    assigns = assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value]) end)
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id} class="cursor-pointer flex items-center gap-3">
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
        <span class="text-sm font-semibold text-base-content/80">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2 w-full">
      <label for={@id} class="flex flex-col w-full">
        <span :if={@label} class="text-sm font-bold text-base-content/80 mb-1.5 ml-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class || "select select-bordered w-full rounded-xl bg-base-100 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all shadow-sm",
            @errors != [] && (@error_class || "select-error focus:ring-error/30")
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="" disabled selected={@value in [nil, ""]}>{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2 w-full">
      <label for={@id} class="flex flex-col w-full">
        <span :if={@label} class="text-sm font-bold text-base-content/80 mb-1.5 ml-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "textarea textarea-bordered w-full rounded-xl bg-base-100 min-h-[100px] focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all shadow-sm",
            @errors != [] && (@error_class || "textarea-error focus:ring-error/30")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2 w-full">
      <label for={@id} class="flex flex-col w-full">
        <span :if={@label} class="text-sm font-bold text-base-content/80 mb-1.5 ml-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "input input-bordered w-full rounded-xl bg-base-100 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all shadow-sm",
            @errors != [] && (@error_class || "input-error focus:ring-error/30")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-1.5 items-center text-xs font-bold text-error ml-1">
      <.icon name="hero-exclamation-circle-mini" class="size-4" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-6"]}>
      <div>
        <h1 class="text-2xl font-black tracking-tight text-base-content">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm font-medium text-base-content/60 mt-1">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

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
    <div class="overflow-x-auto bg-base-100 border border-base-200 rounded-2xl shadow-sm">
      <table class="table w-full">
        <thead class="bg-base-200/50 text-base-content/60 text-xs uppercase tracking-wider font-bold">
          <tr>
            <th :for={col <- @col} class="px-6 py-4">{col[:label]}</th>
            <th :if={@action != []} class="px-6 py-4 text-right">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"} class="divide-y divide-base-200 text-sm">
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="hover:bg-base-200/30 transition-colors group">
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={["px-6 py-4", @row_click && "hover:cursor-pointer"]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="px-6 py-4 text-right font-medium">
              <div class="flex items-center justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="bg-base-100 rounded-2xl border border-base-200 overflow-hidden shadow-sm">
      <dl class="divide-y divide-base-200">
        <div :for={item <- @item} class="px-6 py-4 sm:grid sm:grid-cols-3 sm:gap-4 flex flex-col hover:bg-base-200/30 transition-colors">
          <dt class="text-sm font-bold text-base-content/70">{item.title}</dt>
          <dd class="mt-1 text-sm text-base-content sm:col-span-2 sm:mt-0 font-medium">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :class, :any, default: "size-5"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class, "inline-block align-middle"]} />
    """
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

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
