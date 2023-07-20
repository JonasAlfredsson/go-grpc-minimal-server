package paperclipcounter

import (
	"context"

	pb "github.com/JonasAlfredsson/go-grpc-minimal-server/proto"
)

// PaperclipCounter implements the paper clip counter service.
type PaperclipCounter struct {
	pb.PaperclipCounterServer
	Paperclips int32
}

// NewServer creates an instance of the PaperclipCounter service.
func NewServer() *PaperclipCounter {
	return &PaperclipCounter{
		Paperclips: 1,
	}
}

// GetPaperclips returns the current paper clip count.
func (s *PaperclipCounter) GetPaperclips(_ context.Context, _ *pb.Empty) (*pb.Paperclips, error) {
	return &pb.Paperclips{
		Paperclips: s.Paperclips, // Response will be empty if this is 0.
	}, nil
}

// IncrementPaperclips increments the paperclip count.
func (s *PaperclipCounter) IncrementPaperclips(_ context.Context, size *pb.Size) (*pb.Empty, error) {
	s.Paperclips += size.Paperclips

	return &pb.Empty{}, nil
}
