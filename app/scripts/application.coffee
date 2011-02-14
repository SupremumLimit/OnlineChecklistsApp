root = this


String::starts_with = (str) ->
  this.match("^" + str) == str


String::ends_with = (str) ->
  this.match(str + "$") == str


# add a chainable logging function to jQuery
jQuery.fn.log = (msg) ->
  console.log("%s: %o", msg, this)
  return this


root.append_fn = (fn, fn_to_append) ->
    if !fn?
    	return fn_to_append
    else
	    return ->
        fn()
        fn_to_append()


Backbone.emulateHTTP = true;    # use _method parameter instead of PUT and DELETE HTTP requests



class AppController extends Backbone.Controller
  routes:
    "": "checklists"
    "checklists": "checklists"
    "checklists/:cid/edit": "edit"
    "checklists/:cid": "show"
    "create": "create"
    "users": "users"
    "timeline": "timeline"
    "timeline/:week_offset/u:user_id/c:checklist_id": "timeline"
    "charts": "charts"
    "charts/u:user_ids/c:checklist_id/g:group_by": "charts"

  constructor: ->
    super
    @flash = null


  get_flash: ->
    s = @flash
    @flash = null
    s

  checklists: ->
    @view = new ChecklistListView


  show: (cid) ->
    @view = new ChecklistView { model: Checklists.getByCid(cid) }


  create: ->
    c = new Checklist
    Checklists.add(c)
    @view = new EditChecklistView { model: c }


  edit: (cid) ->
    @view = new EditChecklistView { model: Checklists.getByCid(cid) }


  users: ->
    @view = new UserPageView { users: Users }


  timeline: (week_offset, user_id, checklist_id) ->
    @view = new TimelineView({week_offset: week_offset, users: Users, checklists: Checklists, user_id: user_id, checklist_id: checklist_id})


  charts: (user_ids, checklist_id, group_by)->
    checklist_id = Checklists.at(0).id if !checklist_id?
    group_by = "day" if !group_by?
    @view = new ChartView({user_ids: user_ids, checklist_id: checklist_id, group_by: group_by, users: Users, checklists: Checklists})


#
# Start the app
#

$(document).ready ->
  window.app = new AppController()
  Backbone.history.start()
  $("body").keydown (e) ->
    console.log e.keyCode
    if e.keyCode == 13
      if e.target.name == "for" # Enter pressed on the For text field
        $(".checklist_item").not(".checked").first().toggleClass("selected")
        $(e.target).blur()
        e.preventDefault();
      else      # Enter pressed somewhere else
        if $("#completion_warning").is(":visible")
          $(".complete").click()
          return

        last_selected = $(".checklist_item.selected").last()
        console.log "last_selected: ", last_selected
        next = if last_selected.length > 0 then last_selected.next(".checklist_item") else $(".checklist_item:first")
        console.log "next: ", next
        last_selected.addClass("checked").removeClass("selected")
        if next.length > 0    # we aren't on the last item
          next.addClass("selected")
          $("body").focus()
          e.preventDefault()
        else                  # we are on the last item
          if $(".checklist_item").not(".checked").length == 0   # everything is checked
            $("#completion_warning").show()
            $("#incomplete_warning").hide()
            e.preventDefault()

        # 38 is up, 40 is down

    # if we're in 'for', then select the first item
    # if we've got a selected item, then toggle its checked class and move to the next item


