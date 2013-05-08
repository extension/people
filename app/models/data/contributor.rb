# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Contributor < Person
  has_many :node_activities
  has_many :node_metacontributions

  # note! not unique!
  has_many :meta_contributed_nodes, :through => :node_metacontributions, :source => :node
  has_many :meta_contributed_pages, :through => :meta_contributed_nodes, :source => :page
  has_many :contributed_nodes, :through => :node_activities, :source => :node
  has_many :contributed_pages, :through => :contributed_nodes, :source => :page

  has_many :unique_meta_contributed_nodes, :through => :node_metacontributions, :source => :node, :uniq => true
  has_many :unique_contributed_nodes, :through => :node_activities, :source => :node, :uniq => true

  has_many :unique_meta_contributed_pages, :through => :meta_contributed_nodes, :source => :page, :uniq => true
  has_many :unique_contributed_pages, :through => :contributed_nodes, :source => :page, :uniq => true

  has_many :contributor_groups
  has_many :groups, through: :contributor_groups

  has_many :initial_responded_questions, class_name: 'Question', foreign_key: 'initial_responder_id'
  has_many :question_assignments
  has_many :assigned_question_assignments, class_name: 'QuestionAssignment', foreign_key: 'assigned_by'
  has_many :handled_question_assignments, class_name: 'QuestionAssignment', foreign_key: 'next_handled_by'



  def contributions_by_page
    self.contributed_pages.group("pages.id").select("pages.*, max(node_activities.created_at) as last_contribution_at, group_concat(node_activities.event) as contributions")
  end

  def contributions_by_node
    self.contributed_nodes.group("nodes.id").select("nodes.*, max(node_activities.created_at) as last_contribution_at, group_concat(node_activities.event) as contributions")
  end

   def meta_contributions_by_page
    self.meta_contributed_pages.group("pages.id").select("pages.*, group_concat(node_metacontributions.role) as metacontributions")
  end

  def meta_contributions_by_node
    self.meta_contributed_nodes.group("nodes.id").select("nodes.*, group_concat(node_metacontributions.role) as metacontributions")
  end

  def contributions_count(node_type)
    counts = {}
    counts[:items] = self.contributed_nodes.send(node_type).count('node_id',:distinct => true)
    counts[:actions] = self.contributed_nodes.send(node_type).count
    counts[:byaction] = self.contributed_nodes.send(node_type).group('event').count
    counts
  end

  def metacontributions_count(node_type)
    counts = {}
    counts[:items] = self.meta_contributed_nodes.send(node_type).count('node_id',:distinct => true)
    counts[:actions] = self.meta_contributed_nodes.send(node_type).count
    counts[:byaction] = self.meta_contributed_nodes.send(node_type).group('role').count
    counts
  end



end
