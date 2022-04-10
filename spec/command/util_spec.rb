require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Util do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ util }).should.be.instance_of Command::Util
      end
    end
  end
end

