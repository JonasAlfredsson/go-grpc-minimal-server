package paperclipcounter

import (
	"context"
	"fmt"

	pb "github.com/JonasAlfredsson/go-grpc-minimal-server/proto"
	"golang.org/x/exp/slog"
)

// PaperclipCounter implements the paper clip counter service.
type PaperclipCounter struct {
	pb.PaperclipCounterServer
	logger     *slog.Logger
	Paperclips int32
}

// NewServer creates an instance of the PaperclipCounter service.
func NewServer(logger *slog.Logger) *PaperclipCounter {
	return &PaperclipCounter{
		logger:     logger,
		Paperclips: 1,
	}
}

// GetPaperclips returns the current paper clip count.
func (s *PaperclipCounter) GetPaperclips(_ context.Context, _ *pb.Empty) (*pb.Paperclips, error) {
	s.logger.Info(fmt.Sprintf("Responding with %d paperclips", s.Paperclips))
	return &pb.Paperclips{
		Paperclips: s.Paperclips, // Response will be empty if this is 0.
	}, nil
}

// IncrementPaperclips increments the paperclip count.
func (s *PaperclipCounter) IncrementPaperclips(_ context.Context, size *pb.Size) (*pb.Empty, error) {
	s.logger.Info(fmt.Sprintf("Adding %d paperclips to the current count of %d", size.Paperclips, s.Paperclips))
	s.Paperclips += size.Paperclips

	return &pb.Empty{}, nil
}
