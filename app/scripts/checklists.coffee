root = this

class Item extends Backbone.Model
  defaults: {content: "New item"}

  constructor: ->
    super


  content: ->
    @get "content"


class ItemCollection extends Backbone.Collection
  model: Item

  constructor: ->
    super


class root.Checklist extends Backbone.Model
  defaults: {name: "New checklist"}
  constructor: ->
    super
    @items = new ItemCollection
    @set_items_url()
    #@items.bind("refresh", @f)


  name: ->
    @get "name"


  save: ->
    @set {items: @items}
    super


  set_items_url: ->
    @items.url = "/checklists/#{@id}"


#  validate: (attrs) ->
#    "Please enter a name for the checklist" if attrs.name? && $.trim(attrs.name).length == 0



class ChecklistCollection extends Backbone.Collection
  model: Checklist
  url: "/checklists"

  constructor: ->
    super


class Entry extends Backbone.Model
  url: "/entries"

  constructor: (args) ->
    super



#  checklist: (checklist) ->
#    @set {checklist_id: checklist.id}
#
#
#  for: (content) ->
#    @set {for: content}


#  parse: (response) ->
#    res = _.map response, (attrs, key) ->
#      attrs.checklist
#    res

root.Checklists = new ChecklistCollection


class root.TimeZoneView extends Backbone.View
  tagName: "div"
  id: "content"
  events: {"click #set_time_zone": "set_time_zone"}

  constructor: ->
    super

    $("#" + @id).replaceWith(@el)

    # when the time zone isn't set, show time zone selection thing
    $.get "/time_zone", (data, textStatus, xhr) =>
      @template = _.template """
        Please set the time zone you are in:<br/><br/>
        #{data}
        <br/><br/>This is necessary to get accurate reports.
      """

      @render()


  render: ->
    $(@el).html(@template())
    $("#heading").html("Set time zone")
    document.title = "OnlineChecklists: Set time zone"


  set_time_zone: (e) ->
    current_account.time_zone = $(e.target).prev("select").val()
    $(this).html("Saving...")
    $.post "/time_zone", {time_zone: $(e.target).prev("select").val()}, (data, textStatus, xhr) =>
      $(e.target).html("Set time zone");
      window.location.hash = "checklists";

    e.preventDefault();


class root.ChecklistListView extends Backbone.View
  tagName: "div"
  id: "content"

  events: {
    "click .create": "on_create"
    "click .delete": "on_delete"
    "click .edit": "on_edit"
    "click .name": "on_click"
    "click .confirm_delete": "on_confirm_delete"
    "click .cancel_delete": "on_cancel_delete"
  }

  constructor: ->
    super

    # get rid of any leftover unsaved checklists
    Checklists.refresh(Checklists.select (model) -> model.id?)

    $("#" + @id).replaceWith(@el)

    @template = _.template('''
      <div id = "buttons">
        <a class = "create button" href = "#">Create checklist</a>
        <a class = "button" href = "#timeline">View timeline</a>
        <a class = "button" href = "#charts">View charts</a>
        <% if (current_user.role == "admin") { %> <a class = "button" href = "#users">Invite users</a> <% } %>
      </div>
      <div class = "message" style = "display: none">
        You've reached the limit of your plan with <%= window.Plan.checklists %> checklists.
        <% if (current_user.role == "admin") { %>
          <a href = "/billing">Please consider upgrading to a larger plan</a>.
        <% } else { %>
          Please ask the administrator of your account to upgrade to a larger plan.
        <% } %>
      </div>
      <% if (flash != null) { %>
        <div id = 'flash' class = 'notice'><div><%= flash %></div></div>
      <% } %>
      <% if (checklists.length == 0) { %>
        <div>
          <img src = "/images/up_32.png" style = "display: block; margin-left: 50px; margin-top: 10px; margin-bottom: 10px" />
          It's time to create some checklists because you don't have any!<br/><br/>Press the <b>Create checklist</b> button above to create one.
        </div>
      <% } %>
      <% if (checklists.length > 0) { %>
        <div class = "instructions">Click on a checklist name to fill out that checklist.</div>
      <% } %>
      <ul class = "checklists">
      <% checklists.each(function(checklist) { %>
      <li class = "checklist" id = "<%= checklist.cid %>"><span class = "name"><%= checklist.name() %></span>
        <span class = "controls">
          <a href="#checklists/<%= checklist.cid %>">Fill out</a> |
          <a class = "secondary edit" href = "#checklists/<%= checklist.cid %>/edit">Edit</a> |
          <a class = "secondary delete" id = "delete_<%= checklist.cid %>" href = "#">Delete</a>
        </span>
      </li>
      <% }); %>
      </ul>
      ''')

    @render()


  render: ->
    $(@el).html(@template({checklists : Checklists, flash: window.app.get_flash()}))
    $("#heading").html("Checklists")
    document.title = "OnlineChecklists: Checklists"
    @controls_contents = {}
    #$(".delete").live("click", (e) => @on_delete(e))


  on_create: (e) ->
    if (Checklists.length >= window.Plan.checklists)
      @$(".message").show()
    else
      window.location.hash = "create"
    e.preventDefault()
    e.stopPropagation()


  on_click: (e) ->
    window.location.hash = "checklists/#{@$(e.currentTarget).closest("li").attr("id")}"
    e.preventDefault()
    e.stopPropagation()


  on_edit: (e) ->
    window.location.hash = "checklists/#{@$(e.currentTarget).closest("li").attr("id")}/edit"
    e.preventDefault()
    e.stopPropagation()


  on_delete: (e) ->
    cid = e.target.id.substr(7)
    controls = @$(e.target).closest(".controls")
    @controls_contents[cid] = controls.html()
    controls.html("""
      <b>Delete checklist?</b>
      <a class = 'confirm_delete' id = 'confirm_delete_#{cid}' href = '#'>Delete</a> or
      <a class = 'cancel_delete' id = 'cancel_delete_#{cid}' href = '#'>Cancel</a>
      """)
    e.preventDefault()
    e.stopPropagation()


  on_confirm_delete: (e) ->
    checklist = Checklists.getByCid(e.target.id.substr(15))
    checklist.destroy()
    Checklists.remove(checklist)
    @render()
    #@delegateEvents(@events)
    e.preventDefault()
    e.stopPropagation()


  on_cancel_delete: (e) ->
    controls = @$(e.target).closest(".controls")
    controls.html(@controls_contents[e.target.id.substr(14)])
    e.preventDefault()
    e.stopPropagation()


class root.ChecklistView extends Backbone.View
  tagName: "div"
  id: "content"

  # Enter key is handled in application.coffee because the handler has to be attached to the body element, and it is
  # only created once that way
  events: {
    "click .complete": "on_complete"
    "click .item_select_area": "on_click_item"
    "focus input": "on_focus_input"
    "blur input": "on_blur_input"
    "error": "on_error"
    #"keydown input": "on_keydown"
    #"keydown li": "on_keydown"
  }
  constructor: ->
    super

    @template = _.template('''
      <div class = "input_field">
        Notes: <input name = "notes" type = "text" style = "width: 500px" />
        <span class = "instructions">(press Enter to continue)</span>
      </div>
      <ul style = "margin-bottom: 40px; margin-top: 40px">
      <% items.each(function(item) { %>
      <li class = "checklist_item item_select_area"><div class = "item_select_area" style = "width: 80%"><%= item.content() %></div><span class = "instructions">(press Enter to mark as done)</span></li>
      <% }); %>
      </ul>
      <div class = "message" id = "incomplete_warning" style = "display: none; margin-bottom: 20px">Please complete and check off all the items in the checklist first.</div>
      <div class = "message" id = "completion_message" style = "display: none; margin-bottom: 20px">Press Enter or click Complete! to submit the checklist.</div>
      <button class = "complete">Complete!</button>
      <span style = "margin-left: 20px; margin-right: 10px">or</span>  <a href = "#checklists">Cancel</a>
      ''')

    $("#" + @id).replaceWith(@el)

    @model.items.fetch {success: =>
      @render()
    }


  render: ->
    $(@el).html(@template({items : @model.items}))
    $("#heading").html(@model.name())
    document.title = "OnlineChecklists: #{@model.name()}"
    @$("input[name=notes]").focus().select()


  on_complete: (e) ->
    if @$(".checklist_item").not(".checked").length > 0
      @$("#incomplete_warning").show()
      @$("#completion_message").hide()
      e.preventDefault()
      return

    return if @$(e.target).attr("disabled") is true

    @$(e.target).attr("disabled", true).text("Saving...")
    entry = new Entry({checklist_id: @model.id, notes: @$("input[name=notes]").val()})
    entry.save {},
      { success: (model, response) =>
          window.app.flash = "Completed checklist: #{@model.name()}"
          window.location.hash = "checklists"
        error: (model, error) =>
          @on_error(error)
          @$(e.target).attr("disabled", false).text("Complete!")
      }


  on_click_item: (e) ->
    # the target could be the <li> or the <div> inside it, so we need to make sure we're modifying the <li>
    item_el = if @$(e.target).not("li") then @$(e.target).closest("li") else @$(e.target)
    item_el.toggleClass("checked")
    e.stopPropagation()
    if @$(".checklist_item").not(".checked").length == 0
      @$("#completion_message").show()
    else
      @$("#completion_message").hide()


  on_focus_input: (e) ->
    @$(".checklist_item").removeClass("selected")
    @$(".input_field .instructions").show()

  on_blur_input: (e) ->
    @$(".input_field .instructions").hide()


  on_error: (model, error) ->
    alert(error)


class root.EditItemView extends Backbone.View
  model: Item
  tagName: "li"
  events: {
    "click .remove_item": "on_remove_item"
    "change input[type=text]": "on_change"
  }

  constructor: ->
    super
    @template = _.template('''
      <input type = "text" value = "<%= item.content() %>" style = "width: 80%" /> <a href = "#" class = "remove_item">X</a>
    ''')


  render: ->
    $(@el).html(@template({item: @model}))
    return $(@el)


  on_remove_item: (e) ->
    @collection.remove(@model)
    e.preventDefault()
    e.stopPropagation()


  on_change: (e) ->
    @model.set {"content": $(e.target).val()}


class root.EditChecklistView extends Backbone.View
  events: {
    "click .save": "on_save"
    "click .add_item": "on_add_item"
    "error": "on_error"
  }
  tagName: "div"
  id: "content"

  constructor: ->
    super

    @template = _.template('''
      <div class = "message" style = "display: none"></div>
      Checklist: <input type = "text" class = "checklist_name" style = "width: 80%" value = "<%= name %>" /><br/>
      <br/>
      <ul>
      </ul>
      <ul><li><a class = "button add_item" href = "#">Add step</a></li></ul>
      <br/>
      <br/>
      <button class = "save">Save checklist</button>
      <span style = "margin-left: 20px; margin-right: 10px">or</span>  <a href = "#checklists">Cancel</a>
      ''')

    @model.items.bind "add", @add_item
    @model.items.bind "remove", @remove_item
    @model.items.bind "refresh", @add_items

    #@model.bind("error", (model, error) => @on_error(error))

    $("#" + @id).replaceWith(@el)
    @render()
    @item_el = $(@el).find("ul:first")

    if @model.id?
      @model.items.fetch()
    else
      @model.items.refresh([new Item, new Item, new Item])


  on_save: (e) ->
    if $.trim(@$(".checklist_name").val()).length == 0
      @on_error("Please enter a name for the checklist")
      e.preventDefault()
      return

    return if @$(e.target).attr("disabled") is true

    @$(e.target).attr("disabled", true).text("Saving...")

    @model.set {"name": @$(".checklist_name").val()}

    @model.save {},
      { success: (model, response) =>
          @model.set_items_url()
          window.location.hash = "checklists"
        error: (model, error) =>
          @on_error(error)
          @$(e.target).attr("disabled", false).text("Save checklist")
      }
    e.preventDefault()

  on_add_item: (e) ->
    @model.items.add()
    @$("input[type=text]").last().focus().select()
    @$(e.target).scrollintoview()
    e.preventDefault()
    e.stopPropagation()


  render: ->
    $(@el).html(@template({name: @model.name(), items : @model.items}))
    if !@model.id?
      $("#heading").html("Create checklist")
      document.title = "OnlineChecklists: Create checklist"
    else
      $("#heading").html("Edit #{@model.name()}")
      document.title = "OnlineChecklists: Edit #{@model.name()}"

  add_item: (item) =>
    view = new EditItemView {model: item, collection: @model.items}
    item.view = view
    @item_el.append view.render()


  add_items: =>
    @model.items.each(@add_item)
    @$("input[type=text]").first().focus().select().scrollintoview()


  remove_item: (item) ->
    item.view.remove()


  on_error: (error) =>
    @$(".message").html(error.statusText).show()
