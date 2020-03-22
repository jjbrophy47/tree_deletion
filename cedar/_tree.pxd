import numpy as np
cimport numpy as np

ctypedef np.npy_float32 DTYPE_t          # Type of X
ctypedef np.npy_float64 DOUBLE_t         # Type of y, sample_weight
ctypedef np.npy_intp SIZE_t              # Type for indices and counters
ctypedef np.npy_int32 INT32_t            # Signed 32 bit integer
ctypedef np.npy_uint32 UINT32_t          # Unsigned 32 bit integer

# from ._utils cimport IntStack
from ._manager cimport _DataManager
# from ._splitter cimport Meta
from ._splitter cimport SplitRecord
from ._splitter cimport _Splitter

cdef struct Node:

    # Structure for predictions
    bint   is_leaf             # Whether this node is a leaf
    double value               # Value of node if leaf
    int    feature             # Chosen split feature if decision node
    Node*  left                # Left child node
    Node*  right               # Right child node

    # Extra information
    int    depth               # Depth of node
    bint   is_left             # Whether this node is a left child

    # Metadata necessary for efficient updating
    double p                   # Total probability of chosen feature
    int    count               # Number of samples in the node
    int    pos_count           # Number of pos samples in the node
    int    feature_count       # Number of features in the node
    int*   valid_features      # Array of valid features, shape=[feature_count]
    int*   left_counts         # Array of left sample counts, shape=[feature_count]
    int*   left_pos_counts     # Array of left positive sample counts, shape=[feature_count]
    int*   right_counts        # Array of right sample counts, shape=[feature_count]
    int*   right_pos_counts    # Array of right positive sample counts, shape=[feature_count]
    int*   leaf_samples        # Array of sample indices if leaf, shape=[feature_count]

cdef class _Tree:
    """
    The Tree object is a binary tree structure constructed by the
    TreeBuilder. The tree structure is used for predictions.
    """

    # data specific stucture
    cdef int  n_feature_indices          # Number of features this tree builds on
    cdef int* feature_indices            # Array of features, shape=[n_features]

    # Inner structures
    cdef Node* root                        # Root node
    cdef int node_count                    # Counter for node IDs
    # cdef int capacity                    # Capacity of tree, in terms of nodes
    # cdef double* values                  # Array of values, shape=[capacity]
    # cdef double* p                       # Array of probabilities, shape=[capacity]
    # cdef int*    chosen_features         # Array of chosen features, shape=[capacity]
    # cdef int*    left_children           # Array of left children indices, shape=[capacity]
    # cdef int*    right_children          # Array of right children indices, shape=[capacity]
    # cdef int*    depth                   # Array of depths, shape=[capacity]

    # # Internal metadata, stored for efficient updating
    # cdef int*  count               # Array of sample counts, shape=[capacity]
    # cdef int*  pos_count           # Array of positive sample counts, shape=[capacity]
    # cdef int*  feature_count       # Array of feature counts, shape=[capacity]
    # cdef int** left_counts         # Array of arrays of left counts, shape=[capacity, n_features]
    # cdef int** left_pos_counts     # Array of arrays of left positive counts, shape=[capacity, n_features]
    # cdef int** right_counts        # Array of arrays of right counts, shape=[capacity, n_features]
    # cdef int** right_pos_counts    # Array of arrays of right positive counts, shape=[capacity, n_features]
    # cdef int** features            # Array of arrays of feature indices for decision nodes, shape[capacity, n_features]
    # cdef int** leaf_samples        # Array of arrays of sample indices for leaf nodes, shape[capacity, count]

    # Tree restructuring data
    # cdef IntStack vacant_ids       # Stack of ID numbers for registering nodes

    # Python/C API
    cpdef np.ndarray predict(self, int[:, :] X)
    # cpdef np.ndarray _get_left_counts(self, node_id)
    # cpdef np.ndarray _get_left_pos_counts(self, node_id)
    # cpdef np.ndarray _get_right_counts(self, node_id)
    # cpdef np.ndarray _get_right_pos_counts(self, node_id)
    # cpdef np.ndarray _get_features(self, node_id)
    # cpdef np.ndarray _get_leaf_samples(self, node_id)

    # C API
    cdef _dealloc(self, Node *node)
    # cdef int add_node(self, int parent, bint is_left, bint is_leaf, int feature,
    #                   double value, int depth, int* samples, Meta* meta) nogil
    # cdef void remove_nodes(self, int *node_ids, int n_nodes) nogil
    cdef void _print_counts(self) nogil
    cdef void _counts(self, Node *node) nogil
    cdef np.ndarray _get_double_ndarray(self, double *data, int n_elem)
    cdef np.ndarray _get_int_ndarray(self, int *data, int n_elem)
    # cdef int _resize(self, int capacity=*) nogil

cdef class _TreeBuilder:
    """
    The TreeBuilder recursively builds a Tree object from training samples,
    using a Splitter object for splitting internal nodes and assigning values to leaves.

    This class controls the various stopping criteria and the node splitting
    evaluation order, e.g. depth-first or breadth-first.
    """

    cdef _DataManager manager        # Database manager
    cdef _Splitter splitter          # Splitter object that chooses the attribute to split on
    cdef int min_samples_split       # Minimum number of samples in an internal node
    cdef int min_samples_leaf        # Minimum number of samples in a leaf
    cdef int max_depth               # Maximal tree depth
    cdef int random_state            # Random state

    # Python API
    cpdef void build(self, _Tree tree)

    # C API
    cdef Node* _build(self, int** X, int* y, int* samples, int n_samples,
                      int* features, int n_features,
                      int depth, bint is_left, double parent_p) nogil
    cdef void _set_leaf_node(self, Node** node_ptr, int* y, int* samples, int n_samples) nogil
    cdef void _set_decision_node(self, Node** node_ptr, SplitRecord* split) nogil
    # cdef double _leaf_value(self, int* y, int* samples, int n_samples, Meta* meta) nogil
