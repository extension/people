class AdminConstraint
  def matches?(request)
    return false unless request.session[:person_id]
    person = Person.find(request.session[:person_id])
    person && person.signin_allowed? && person.is_admin?
  end
end
