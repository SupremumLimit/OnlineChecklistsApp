class ChecklistsController < ApplicationController
  def index
    @checklists = current_account.checklists.order("id").all
    respond_to { |format|
      format.json { render :json => @checklists }
      format.html { render "index" }
    }
  end

  def show
    checklist = current_account.checklists.find(params[:id])
    respond_to { |format|
      format.json { render :json => checklist.items.order("id") }
    }
  end

  def create
    checklist = current_account.checklists.create(:name => params[:name])
    params[:items].each { |item|
      checklist.items.create :content => item[:content]
    }

    respond_to { |format|
      format.json { render :json => checklist, :status => :ok }
    }
  end

  def update
    checklist = current_account.checklists.find(params[:id])
    checklist.name = params[:name]
    checklist.save
    checklist.item_ids = params[:items].map {|item| item[:id]}
    params[:items].each {|item|
      if item[:id]
        existing_item = checklist.items.find(item[:id])
        existing_item.content = item[:content]
        existing_item.save
      else
        checklist.items.create :content => item[:content]
      end
    }


    respond_to { |format|
      format.json { render :json => {}, :status => :ok }
    }
  end

  def destroy
    checklist = checklist = current_account.checklists.find(params[:id])
    checklist.destroy
    respond_to { |format|
      format.json { render :json => {}, :status => :ok }
    }
  end
end
