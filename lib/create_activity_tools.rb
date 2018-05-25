# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

# this module is completely meant to extend Person - it's just meant
# to get these class methods out of the already quite large Person model
module CreateActivityTools

  def create_workflow_counts(published_content_only = true)
    if(published_content_only)
      # first get a list of the currently published create nodes
      published_create_nodes = ArticlesPage.where("create_node_id IS NOT NULL").pluck(:create_node_id)
    end

    workflow_counts = {}
    CreateWorkflowEvent.find_each do |cwe|
      next if (published_content_only and !published_create_nodes.include?(cwe.node_id))
      if(workflow_counts[cwe.user_id])
        workflow_counts[cwe.user_id][:workflow_count] += 1
        if(cwe.created_at > workflow_counts[cwe.user_id][:latest_workflow_activity])
          workflow_counts[cwe.user_id][:latest_workflow_activity] = cwe.created_at
        end
      else
        # init person counts
        workflow_counts[cwe.user_id] = {workflow_count: 1, latest_workflow_activity: cwe.created_at}
      end
    end
    workflow_counts
  end


  def create_workflow_counts_csv(published_content_only = true,exportfile = "./data/create_workflow_counts.csv")
    workflow_counts = create_workflow_counts(published_content_only)

    CSV.open(exportfile, "wb") do |csv|
      csv << ['person_id','name','email','retired account?','last_active_at','workflow_changes','latest_workflow_activity_at']
      workflow_counts.each do |person_id,values|
        if(p = Person.find_by_id(person_id))
          row = []
          row << person_id
          row << p.fullname
          row << p.email
          row << (p.retired? ? 'Yes' : ' No')
          row << p.last_activity_at.to_s
          row << values[:workflow_count]
          row << values[:latest_workflow_activity].to_s
          csv << row
        end
      end
    end
  end


  def create_revision_counts(published_content_only = true)
    if(published_content_only)
      # first get a list of the currently published create nodes
      published_create_nodes = ArticlesPage.where("create_node_id IS NOT NULL").pluck(:create_node_id)
    end

    revision_counts = {}
    CreateRevision.find_each do |cr|
      next if (published_content_only and !published_create_nodes.include?(cr.nid))
      if(revision_counts[cr.uid])
        revision_counts[cr.uid][:revision_count] += 1
        if(cr.created_at > revision_counts[cr.uid][:latest_revision_activity])
          revision_counts[cr.uid][:latest_revision_activity] = cr.created_at
        end
      else
        # init person counts
        revision_counts[cr.uid] = {revision_count: 1, latest_revision_activity: cr.created_at}
      end
    end
    revision_counts
  end


  def create_revision_counts_csv(published_content_only = true,exportfile = "./data/create_revision_counts.csv")
    revision_counts = create_revision_counts(published_content_only)

    CSV.open(exportfile, "wb") do |csv|
      csv << ['person_id','name','email','retired account?','last_active_at','revisions','latest_revision_activity_at']
      revision_counts.each do |person_id,values|
        if(p = Person.find_by_id(person_id))
          row = []
          row << person_id
          row << p.fullname
          row << p.email
          row << (p.retired? ? 'Yes' : ' No')
          row << p.last_activity_at.to_s
          row << values[:revision_count]
          row << values[:latest_revision_activity].to_s
          csv << row
        end
      end
    end
  end

end
