class ProMembershipsController < ApplicationController

  before_filter :authenticate_user!

  def create
    params.permit(:token, :plan_id, :gift, :gifted_to, :gift_message)

    if params[:token].blank?
      return render(text: "Didn't get credit card details from Stripe", status: 400)
    end

    if params[:plan_id].blank?
      return render(text: "No membership plan was selected", status: 400)
    end

    token, plan_id = params[:token], params[:plan_id].to_i

    begin
      plan = ProMembershipPlan.find(plan_id)
    rescue ActiveRecord::RecordNotFound
      return render(text: "No such membership plan exists", status: 400)
    end

    begin
      if params[:gift]
        gift_to = User.find(params[:gift_to])
        manager.gift! plan, token, gift_to, params[:gift_message]
      else
        manager.subscribe! plan, token
      end
    rescue
      return render(text: "Couldn't charge your credit card", status: 400)
    end

    render text: "subscription successful"
  end

  def destroy
    manager.cancel!
    render text: "unsubscribed"
  end

  private

  def manager
    ProMembershipManager.new(current_user)
  end

end
