#include <hls_stream.h>
#include <ap_axi_sdata.h>
#include <ap_int.h>

typedef ap_axiu<32, 0, 0, 0> axi_stream_t;
typedef ap_uint<8> pixel_t;

void gaussian_blur(hls::stream<axi_stream_t> &in_stream, hls::stream<axi_stream_t> &out_stream) {
#pragma HLS INTERFACE axis port=in_stream
#pragma HLS INTERFACE axis port=out_stream
#pragma HLS PIPELINE II=1

    static pixel_t line_buffer[2][640];
#pragma HLS ARRAY_PARTITION variable=line_buffer complete dim=1

    static pixel_t window[3][3];
#pragma HLS ARRAY_PARTITION variable=window complete dim=0

    static int x = 0;
    static int y = 0;

    // Read input pixel
    axi_stream_t in_data = in_stream.read();
    pixel_t pixel_in = in_data.data.range(7, 0);

    // Shift window
    window[0][0] = window[0][1];
    window[0][1] = window[0][2];
    window[1][0] = window[1][1];
    window[1][1] = window[1][2];
    window[2][0] = window[2][1];
    window[2][1] = window[2][2];

    window[2][2] = pixel_in;

    // Update line buffer
    line_buffer[0][x] = window[1][2];
    line_buffer[1][x] = window[0][2];

    axi_stream_t out_data;
    out_data.data = 0;
    out_data.keep = -1;  // All bytes are valid
    out_data.strb = -1;  // All bytes are valid
    out_data.user = in_data.user;
    out_data.last = in_data.last;

    if (y >= 2 && x >= 2) {
        int sum = 0;
        sum += window[0][0] + 2 * window[0][1] + window[0][2];
        sum += 2 * window[1][0] + 4 * window[1][1] + 2 * window[1][2];
        sum += window[2][0] + 2 * window[2][1] + window[2][2];
        sum = sum / 16;
        pixel_t pixel_out = (pixel_t)sum;
        out_data.data.range(7, 0) = pixel_out;
    }

    out_stream.write(out_data);

    // Update x, y coordinates
    x++;
    if (x == 640) {
        x = 0;
        y++;
        if (y == 480) {
            y = 0;
        }
    }
}
