describe Catalog::UpdateOrderItem, :type => [:topology, :service] do
  let(:subject) { described_class.new(topic, task, order_item) }
  let(:topic) { Struct.new(:payload, :message).new(payload, "message") }
  let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:service_instance => {:id => service_instance_id}}) }
  let(:service_instance_id) { "321" }

  describe "#process" do
    let(:payload) { {"task_id" => "123", "status" => status, "state" => state, "context" => "payloadcontext"} }
    # let(:order_item) { instance_double(OrderItem, :service_instance_ref => 213) }
    let(:order_item) { create(:order_item, :service_instance_ref => 213) }

    before do
      allow(order_item).to receive(:update_message)
      allow(order_item).to receive(:mark_completed)
      allow(order_item).to receive(:mark_failed)
    end

    shared_examples_for "#process info message" do
      it "updates the order item with an info message" do
        expect(order_item).to receive(:update_message).with("info", "Task update message received with payload: #{payload}")
        subject.process
      end
    end

    context "when the status of the task is ok" do
      let(:status) { "ok" }

      context "when the state is completed" do
        let(:state) { "completed" }

        context "when the task has a service instance id" do
          it_behaves_like "#process info message"

          it "marks the item as completed with the correct service instance id" do
            expect(order_item).to receive(:mark_completed).with("Order Item Complete", :service_instance_ref => "321")
            subject.process
          end
        end

        context "when the task does not have a service instance id" do
          let(:service_instance_id) { nil }

          it_behaves_like "#process info message"

          it "marks the item as completed with the correct service instance id" do
            expect(order_item).to receive(:mark_completed).with("Order Item Complete", :service_instance_ref => "213")
            subject.process
          end
        end
      end

      context "when the state is running" do
        let(:state) { "running" }
        let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:service_instance => {:url => "http://tower.com/job/3"}}) }

        it "sends two update messages" do
          expect(order_item).to receive(:update_message).with("info", "Task update message received with payload: #{payload}")
          expect(order_item).to receive(:update_message).with("info", "Order Item being processed with context: payloadcontext")
          subject.process
        end

        it "updates the order item with the external url" do
          subject.process
          order_item.reload
          expect(order_item.external_url).to eq("http://tower.com/job/3")
        end
      end
    end

    context "when the status of the task is error" do
      let(:status) { "error" }
      let(:state) { "bar" }

      context "when the task has a service instance id" do
        it "marks the item as failed with the proper id" do
          expect(order_item).to receive(:mark_failed).with("Order Item Failed", :service_instance_ref => "321")
          subject.process
        end

        it_behaves_like "#process info message"
      end

      context "when the task does not have a service instance id" do
        let(:service_instance_id) { nil }

        it "marks the item as failed with the proper id" do
          expect(order_item).to receive(:mark_failed).with("Order Item Failed", :service_instance_ref => "213")
          subject.process
        end

        it_behaves_like "#process info message"
      end
    end

    context "when the status of the task is anything else" do
      let(:status) { "foo" }
      let(:state) { "bar" }

      it_behaves_like "#process info message"
    end
  end
end