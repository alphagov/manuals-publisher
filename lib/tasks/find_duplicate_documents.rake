require 'duplicate_document_finder'

desc "Find duplicate documents"
task find_duplicate_documents: :environment do
  DuplicateDocumentFinder.new.execute
end
