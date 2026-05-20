class Defects::ClassificationsController < AuthenticatedController
  # POST /defects/classify  (json)
  def create
    text = [params[:title], params[:description]].compact.join(" ")
    suggestion = DefectClassifier.suggest(text, organization: Current.organization)
    render json: suggestion
  end
end
